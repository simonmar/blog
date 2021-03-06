---
layout: post
title: Hotswapping Haskell
description: ""
category: ghc
tags: [ghc]
---

*This is a guest post by <a href="https://github.com/JonCoens">Jon
 Coens</a>. Jon worked on the Haxl project since the beginning in
 2013, and nowadays he works on broadening Haskell use within Facebook.*

From developing code through deployment, Facebook needs to move fast. This is especially true for one of our <a href="https://code.facebook.com/posts/745068642270222/fighting-spam-with-haskell/">anti-abuse systems</a> that deploys hundreds of code changes every day. Releasing a large application (hundreds of Kloc) that many times a day presents plenty of intriguing challenges. Haskell's strict type system means we're able to confidently push new code knowing that we can't crash the server, but getting those changes out to many thousands of machines as fast as possible requires some ingenuity.

Given the application size and deployment speed constraints:

* Building a new application binary for every change would take too long

* Starting and tearing down millions of heavy processes a day would create undue churn on other infrastructure

* Splitting the service into multiple smaller services would slow down developers.

To overcome these constraints, our solution is to build a shared object file that contains only the set of frequently changing business logic and dynamically load it into our server process. With some clever house-keeping, the server drops old unneeded shared objects to make way for new ones without dropping any requests.

It's like driving a car down the road, having a new engine fall into your lap, installing it on-the-fly, and dumping the old engine behind you, all while never touching the brakes.

## Show Me The Code!

For those who want a demo, look <a href="https://github.com/fbsamples/ghc-hotswap">here</a>. Make sure you have GHC 8.2.1 or later, then follow the <a href="https://github.com/fbsamples/ghc-hotswap/blob/master/README.md">`README`</a> for how to configure the projects.

## What about...

### A Statically built server

The usual way of deploying updates requires building a fully statically-linked binary and shipping that to every machine. This has many benefits, the biggest of which being streamlined and well-understood deployment, but results in long update times due to the size of our large final binary. Each business logic change, no matter how small, needs to re-link the entire binary and be shipped out to all machines. Both binary link time and distribution time are correlated with file size, so the larger the binary, the longer the updates. In our case, the application binary's size is too large for us to do frequent updates by this method.

### GHCi-as-a-service

GHCi's incremental module reloading is another way of updating code quickly. Mimicking the local development workflow, you could ship code updates to each service, and instruct them to reload as necessary. Continually re-interpreting the code significantly decreases the amount of time to distribute an update. In fact, a previous version of our application (not based on Haskell) worked this way. This approach severely hinders performance, however. Running interpreted code is strictly slower than optimized compiled code, and GHCi can't currently handle running multiple requests at the same time.

The model of reloading libraries in GHCi closely matches what we want our end behavior to look like. What about loading those libraries into a non-interpreted Haskell binary?

## Shipping shared objects for great good

Using the `GHCi.Linker` API, our update deployment looks roughly as follows:

* Commit a code change onto trunk

* Incrementally build a shared object file containing the frequently-changing business logic

* Ship that file to each machine

* In each process, use GHCi's dynamic linker to load in the new shared object and lookup a symbol from it (while continuing to serve requests using the previous code)

* If all succeeds, start serving requests using the new code and mark the previous shared object for unloading by the GC

This minimizes the amount of time between making a code change and having it running in an efficient production environment. It only rebuilds the minimum set of code, deploys a much smaller file to each server, and keeps the server running through each update.

Not every module or application can follow this update model as there are some crucial constraints to consider when figuring out what can go into the shared object.

1. The symbol API boundaries into and out of the shared object must remain constant
2. The main binary cannot persist any reference to code or data originating from the shared object, because that will prevent the GC from unloading the object.

Fortunately, our use-case fits this mold.

## Details

We'll talk about a handful of libraries + example code

* <a href="https://downloads.haskell.org/~ghc/master/libraries/ghci/ghci/GHCi-ObjLink.html">**GHCi.ObjLink**</a> - A library provided by GHC

* <a href="https://github.com/fbsamples/ghc-hotswap/tree/master/ghc-hotswap">**ghc-hotswap**</a> - A library to use

* <a href="https://github.com/fbsamples/ghc-hotswap/tree/master/ghc-hotswap-types">**ghc-hotswap-types**</a> - User-written code to define the API

* <a href="https://github.com/fbsamples/ghc-hotswap/tree/master/ghc-hotswap-so">**ghc-hotswap-so**</a> - User-written code that lives in the shared object

* <a href="https://github.com/fbsamples/ghc-hotswap/tree/master/ghc-hotswap-demo">**ghc-hotswap-demo**</a> - User-written application utilizing the above

### Loading and extracting from the shared object

Let's start with bringing in a new shared object, the guts of which can be found in <a href="https://github.com/fbsamples/ghc-hotswap/blob/master/ghc-hotswap/GHC/Hotswap.hs">loadNewSO</a>. It makes heavy use of the <a href="https://github.com/ghc/ghc/blob/master/libraries/ghci/GHCi/ObjLink.hs">GHCi.ObjLink</a> library.
We need the name of an exported symbol to lookup inside the shared object (`symName`) and the file path to where the shared object lives (`newSO`). With these, we can return an instance of some data that originates from that shared object.

```
initObjLinker DontRetainCAFs
```

GHCi's linker needs to be initialized before use, and fortunately the call is idempotent. “DontRetainCAFs” tells the linker and GC not to retain CAFs (Constant Applicative Forms, i.e. top-level values) in the shared object.  GHCi normally retains all CAFs as the user can type an expression that refers to anything at all, but for hot-swapping this would prevent the object from being unloaded as we would have references into the object from the heap-resident CAFs.

```
loadObj newSO
resolved <- resolveObjs
unless resolved $
  ...
```

This maps the shared object into the memory of the main process, brings the shared object's symbols into GHCi's symbol table, and ensures any undefined symbols in the SO are present in the main binary. If any of these fail, an exception is thrown.

```
c_sym <- lookupSymbol symName
```

Here we ask GHCi's symbol table if the given name exists, and returns a pointer to that symbol.

```
h <- case c_sym of
  Nothing -> throwIO ...
  Just p_sym ->
    bracket (callExport $ castPtrToFunPtr p_sym) freeStablePtr deRefStablePtr
```

When getting a pointer to the symbol (`Just p_sym`), a couple things happen. We know that the underlying symbol is a function (as we'll ensure later), so we cast it to a function pointer. A `FunPtr` doesn't do us much good on its own, so use `callExport` to turn it into a callable Haskell function as well as execute the function. This call is the first thing to run code originating from the shared object. Since our call returns a `StablePtr a`, we dereference and then free the stable pointer, resulting in our value of type a from the shared object.

We want to query the shared object and get a Haskell value back.  The best way to do that safely and without baking in too much low-level knowledge is for the shared object to expose a function using `foreign export`. The Haskell value must therefore be returned wrapped in a `StablePtr`, and so we have to get at the value itself using `deRefStablePtr`, before finally releasing the `StablePtr` with `freeStablePtr`.

```
purgeObj newSO
return h
```

Assuming everything has gone well, we purge GHCi's symbol table of all symbols defined from our shared object and then return the value we retrieved. Purging the symbols makes room for the next shared object to come in and resolve successfully without fully unloading the shared object that we're actively holding references to. We could tell GHCi to unload the shared object at this point, but this would cause the GC to aggressively crawl the entire shared object every single time, which is a lot of unnecessary work. Purging retains the code in the process to make the GC's work lighter while making room for the next shared object. See *Safely Transition Updates* for when to unload the shared object.

The project that defines the code for the shared object must be generated in a relocatable fashion. It must be configured with the `—enable-library-for-ghci` flag, otherwise `loadObj` and `resolveObj` will throw a fit.

### Defining the shared object's API

During compilation, the function names from code turn into quasi-human-readable symbol names. Ensuring you look up the correct symbol name from a shared object can become brittle if you rely on hardcoded munged names. To mitigate this, we define a single data type to house all the symbols we want to expose to the main application, and export a ccall using Haskell's Foreign library. This guarantees we can export a particular symbol with a name we control.
Placing all our data behind a single symbol (that both the shared object and main binary can depend on), we reduce the coupling to only a couple of points.

Let's look at <a href="https://github.com/fbsamples/ghc-hotswap/blob/master/ghc-hotswap-types/Types.hs">Types.hs</a>.

```
data SOHandles = SOHandles
  { someData :: Text
  , someFn :: Int -> IO ()
  } deriving (Generic, NFData)
```

Here's our common structure for everything we want to expose out of the shared object. Notice that you can put constants, like `someData`, as well as full functions to execute, like `someFn`.

```
type SOHandleExport = IO (StablePtr SOHandles)
```

This defines the type for the extraction function the main binary will run to get an instance of the handles from the shared object

```
foreign import ccall "dynamic"
  callExport :: FunPtr SOHandleExport -> SOHandleExport
```

Here we invoke Haskell's FFI to generate a function that calls a function pointer to our export function as an actual Haskell function. The “dynamic” parameter to ccall <a href="https://www.haskell.org/onlinereport/haskell2010/haskellch8.html">does exactly this</a>. We saw using this earlier when loading in a shared object.

Next let's look at code for the <a href="https://github.com/fbsamples/ghc-hotswap/blob/master/ghc-hotswap-so/SO/Handles.hs">shared object itself</a>.
Note that we depend on and import the `Types` module defined in `ghc-hotswap-types`.

```
foreign export ccall "hs_soHandles"
  hsNewSOHandle :: SOHandleExport
```

This uses the FFI to explicitly export a Haskell function called `hsNewSOHandle` as a symbol named `“hs_soHandles”`. This is the function our main binary is going to end up calling, so set its type to our export function.

```
hsNewSOHandle = newStablePtr SOHandles
  { ...
  }
```

In our definition of this function, we return a stable pointer to an instance of our data type, which will end up being read by our main application

Using these common types, we've limited the amount of coupling down to using `callExport`, exporting the symbol as “hs_soHandles” from the shared object, and can combine these in our usage of `loadNewSO`.

### Safely Transition Updates

With some extra care, we can cleanly transition to new shared objects while minimizing the amount of work the GC needs to do.

Let's look closer at <a href="https://github.com/fbsamples/ghc-hotswap/blob/master/ghc-hotswap/GHC/Hotswap.hs">Hotswap.hs</a>.

`registerHotswap` uses `loadNewSO` to load the first shared object and then provides some accessor functions on the data extracted. We save some state associated with the shared object: the path to the object, the value we extract, as well as a lock to keep track of usage.

The `unWrap` function reads the state for the latest shared object and runs a user-supplied action on the extracted value. Wrapping the user-function in the read lock ensures we won't accidentally try to remove the underlying code while actively using it. Without this, we run the risk of creating unnecessary stress on the GC.

The updater function (`updateState`) assumes we already have one shared object mapped into memory with its symbol table purged.

```
newVal <- force <$> loadNewSO dynamicCall symbolName nextPath
```

We first attempt to load in the next shared object located at `nextPath`, using the same export call and symbol name as before. At this point we actually have two shared objects mapped into memory at the same time; one being the old object that's actively being used and the other being the new object with our desired updates.

Next we build some state associated with this object, and swap our state MVar.

```
oldState <- swapMVar mvar newState
```

After this call, any user that uses `unWrap` will get the new version of code that was just loaded up. This is when we would observe the update being “live” in our application.

```
L.withWrite (lock oldState) $
  unloadObj (path oldState)
```

Here we finally ask the GC to unload the old object. Once the write lock is obtained, no readers are present, so nothing can be running code from this old shared object (unless one is nefariously holding onto some state). Calling `unloadObj` doesn't immediately unmap the object, as it only informs the GC that the object is valid to be dumped. The next major GC ensures that no code is referencing anything from that shared object and will fully dump it out.

At this point we now have only the next shared object mapped in memory and being used in the main application.

## Shortcomings / Future work

### Beware sticky shared objects

The trickiest problem we've come across has been when the GC doesn't want to drop old shared objects. Eventually so many shared objects are linked at once that the process runs out of space to load in a new object, stalling all updates until the process is restarted.  We'll call this problem *shared object retention*, or just *retention*.

An object is unloaded when (a) we've called `unloadObj` on it, and (b) the GC determines that there are no references from heap data into the object.  Retention can therefore only happen if we have some persistent data that lives across a shared object swap. Obviously it's better if you can avoid this, but sometimes it's necessary: e.g. in Sigma the persistent data consists of the pre-initialized data sources that we use with the Haxl monad, amongst other things.  The first step in avoiding retention is to be very clear about what this data is, and to fully audit it.

To get retention, the persistent data must be mutable in some way (e.g. contain an `IORef`), and for retention to occur we must write something into the persistent `IORef` during the course of executing code from the shared object.  The data we wrote into the `IORef` can end up referring to the shared object in two ways:

* If it contains a thunk or a function, these will refer to code in the shared object.

* If it contains data where the datatype is defined in the shared object (rather than in the packages that the object depends on, which are statically linked), then again we have a reference from the heap-resident data into the shared object, which will cause retention.

So to avoid retention while having mutable persistent data, the rules of thumb are:

1. `rnf` everything before writing into the persistent `IORef`, and ensure that any manual `NFData` instances don't lie.

2. Don't store values that contain functions

3. Don't store values that use datatypes defined in the shared object

Debugging retention problems can be really hard, involving attaching to the process with gdb and then following the offending references from the heap.  We hope that the new DWARF support in GHC 8.2 will be able to help here.

### Linker addressable memory is limited

Calling the built file a shared object is a bit of a misnomer, as it isn't compiled with `-fPIC` and is actually just an object file. Files like these can only be loaded into the lower 2GB of memory (x86_64 small memory model uses 32 bit relative jumps), which can become restrictive when your object file gets large. Since the update mechanism relies on having multiple objects in memory at the same time, fragmentation of the mappable address space can become a problem. We've already made a few improvements to the GHCi linker to reduce the impact of these problems, but we're running out of options.

Ideally we'd switch to using true shared objects (built with `-fPIC`) to remove this limitation.  It requires some work to get there, though: GHC's dynamic linking support is designed to support a model where each package is in a separate shared library, whereas we want a mixed static/dynamic model.

<a href="https://github.com/JonCoens">*Jon Coens*<a>
