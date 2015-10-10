---
layout: post
title: Fun With Haxl (Part 1)
description: ""
category: haxl
tags: [haxl]
---

This is a blog-post version of a talk I recently gave at the <a
href="https://skillsmatter.com/conferences/7069-haskell-exchange-2015">Haskell
eXchange 2015</a>.  The video of the talk is <a
href="https://skillsmatter.com/skillscasts/6644-keynote-from-simon-marlow">here</a>,
but there were a lot of questions during the talk which aren't very
audible on the video, so hopefully this post will be useful to folks
who weren't at the event.

If you want to play with the examples yourself, the code is available
<a href="https://github.com/simonmar/haskell-eXchange-2015">on
github</a>, and to run the examples you'll need to `cabal install haxl
sqlite` first, or the `stack` equivalent.

## What is Haxl?

<a href="https://github.com/facebook/Haxl">Haxl</a> is a library that
was developed for solving a very specific problem at Facebook: we
wanted to write purely functional code, including data-fetching
operations, and have the data-fetches automatically batched and
performed concurrently as far as possible.  This is exactly what Haxl
does, and it has been <a
href="https://code.facebook.com/posts/745068642270222/fighting-spam-with-haskell/">running
in production at Facebook</a> as part of the anti-abuse infrastructure
for nearly a year now.

Although it was designed for this specific purpose, we can put Haxl to
use for a wide range of tasks where implicit concurrency is needed:
not just data-fetching, but other remote data operations (including
writes), and it works perfectly well for batching and overlapping
local I/O operations too.  In this blog post (series) I'll start by
reflecting on how to use Haxl for what it was intended for, and then
move on to give examples of some of the other things we can use Haxl
for.  In the final example, I'll use Haxl to implement a parallel
build system.

## Example: accessing data for a blog

Let's suppose you're writing a blog (an old-fashioned one with
dynamically-generated pages!) and you want to store the content and
metadata for the blog in a database.  I've made an example database
called `blog.sqlite`, and we can poke around to see what's in it:

```
$ sqlite3 blog.sqlite
SQLite version 3.8.2 2013-12-06 14:53:30
Enter ".help" for instructions
Enter SQL statements terminated with a ";"
sqlite> .tables
postcontent  postinfo     postviews  
sqlite> .schema postinfo
CREATE TABLE postinfo(postid int, postdate timestamp, posttopic text);
sqlite> .schema postcontent
CREATE TABLE postcontent(postid int, content text);
sqlite> select * from postinfo;
1|2014-11-20 10:00:00|topic1
2|2014-11-20 10:01:00|topic2
3|2014-11-20 10:02:00|topic3
...
sqlite> select * from postcontent;
1|example content 1
2|example content 2
3|example content 3
...
```

There are a couple of tables that we're interested in: `postinfo`,
which contains the metadata, and `postcontent`, which contains the
content.  Both are indexed by `postid`, an integer key for each post.

Now, let's make a little Haskell API for accessing the blog data.
I'll do this twice: first by calling an SQL library directly, and then
using Haxl, to compare the two.

The code for the direct implementation is in <a href="https://github.com/simonmar/haskell-eXchange-2015/blob/3ae0e34a051201eb77721bee2e940ec1f764a0df/BlogDB.hs">BlogDB.hs</a>, using
the simple `sqlite` package for accessing the sqlite DB (there are
other more elaborate and type-safe abstractions for accessing
databases, but that is orthogonal to the issues we're interested in
here, so I'm using `sqlite` to keep things simple).

In our simple API, there's a monad, `Blog`, in which we can access the
blog data, a function `run` for executing a `Blog` computation, and
two operations, `getPostIds` and `getPostContent` for making specific
queries in the `Blog` monad.  To summarise:

```haskell
type Blog a  -- a monad

run :: Blog a -> IO a

type PostId = Int
type PostContent = String

getPostIds     :: Blog [PostId]
getPostContent :: PostId -> Blog PostContent
```

The implementation of the API will print out the queries it is making,
so that we can see what's happening when we call these functions.
Let's use this API to query our example DB:

```
GHCi, version 7.11.20150924: http://www.haskell.org/ghc/  :? for help
[1 of 1] Compiling BlogDB           ( BlogDB.hs, interpreted )
Ok, modules loaded: BlogDB.
*BlogDB> run getPostIds
select postid from postinfo;
[1,2,3,4,5,6,7,8,9,10,11,12]
*BlogDB> run $ getPostIds >>= mapM getPostContent
select postid from postinfo;
select content from postcontent where postid = 1;
select content from postcontent where postid = 2;
select content from postcontent where postid = 3;
select content from postcontent where postid = 4;
select content from postcontent where postid = 5;
select content from postcontent where postid = 6;
select content from postcontent where postid = 7;
select content from postcontent where postid = 8;
select content from postcontent where postid = 9;
select content from postcontent where postid = 10;
select content from postcontent where postid = 11;
select content from postcontent where postid = 12;
["example content 1","example content 2","example content 3","example content 4","example content 5","example content 6","example content 7","example content 8","example content 9","example content 10","example content 11","example content 12"]
*BlogDB> 
```

## The problem: batching queries

Now, the issue with this API is that every call to `getPostContent`
results in a separate `select` query.  The `mapM` call in the above
example gave rise to one `select` query to fetch the contents of each
post separately.

Ideally, rather than

```
select content from postcontent where postid = 1;
select content from postcontent where postid = 2;
select content from postcontent where postid = 3;
```

What we would like to see is something like

```
select content from postcontent where postid in (1,2,3);
```

This kind of batching is particularly important when the database is
remote, or large, or both.

One way to solve the problem is to add a new API for this query, e.g.:

```haskell
multiGetPostContents :: [PostId] -> IO [PostContent]
```

But there are several problems with this:

* Clients have to remember to call it, rather than using `mapM`.

* If we're fetching post content in multiple parts of our code, we
  would have to arrange to do the fetching in one place and plumb the
  results to the places that need the data, which might involve
  restructuring our code in an unnatural way, purely for efficiency
  reasons.

* From a taste perspective, `multiGetPostContents` duplicates
  the functionality of `mapM getPostContent`, which is ugly.

This is the problem that Haxl was designed to solve.  We'll look at
how to implement this API on top of Haxl in the next couple of sections, but
just to demonstrate the effect, let's try it out first:

```
Prelude> :l HaxlBlog
[1 of 2] Compiling BlogDataSource   ( BlogDataSource.hs, interpreted )
[2 of 2] Compiling HaxlBlog         ( HaxlBlog.hs, interpreted )
Ok, modules loaded: HaxlBlog, BlogDataSource.
*HaxlBlog> run $ getPostIds >>= mapM getPostContent
select postid from postinfo;
select postid,content from postcontent where postid in (12,11,10,9,8,7,6,5,4,3,2,1)
["example content 1","example content 2","example content 3","example content 4","example content 5","example content 6","example content 7","example content 8","example content 9","example content 10","example content 11","example content 12"]
*HaxlBlog>
```

Even though we used the standard `mapM` function to perform multiple
`getPostContent` calls, they were batched together and executed as a
single `select` query.

## Introduction to Haxl

You can find the full documentation for Haxl <a
href="http://hackage.haskell.org/package/haxl">here</a>, but in this
section I'll walk through the most important parts, and then we'll
implement our own data source for the blog database.

Haxl is a Monad:

```haskell
newtype GenHaxl u a

instance Functor (GenHaxl u)
instance Applicative (GenHaxl u)
instance Monad (GenHaxl u)
```

It is generalised over a type variable `u`, which can be used to pass
around some user-defined data throughout a Haxl computation.  For
example, in our application at Facebook we instantiate `u` with the
data passed in with the request that we're processing.

Essentially there is a `Reader` monad built-in to Haxl. (this might
not be the cleanest design, but it is the way it is.)  Throughout the
following we're not going to be using the `u` parameter, and I'll
often instantiate it with `()`, like this:

```haskell
type Haxl a = GenHaxl () a
```

The most important operation in Haxl is `dataFetch`:

```haskell
dataFetch :: (DataSource u r, Request r a) => r a -> GenHaxl u a
```

This is how a user of Haxl fetches some data from a *data source*
(in our example, from the blog database).  The Haxl library is designed
so that you can use multiple user-defined data sources simultaneously.

The argument of type `r a` is a request, where `r` is the request type
constructor, and `a` is the type of the result we're expecting.  The
`r` type is defined by the data source you're using, which should also
supply appropriate instances of `DataSource` and `Request`.  For
example, the request type for our blog looks like this:

```haskell
data BlogRequest a where
  FetchPosts       :: BlogRequest [PostId]
  FetchPostContent :: PostId -> BlogRequest PostContent
```

Note that we're using a GADT, because we have two different requests
which each produce a result of a different type.

Next, our request type needs to satisfy the `Request` constraint.
`Request` is defined like this:

```haskell
type Request req a =
  ( Eq (req a)
  , Hashable (req a)
  , Typeable (req a)
  , Show (req a)
  , Show a
  )
```

That is, it is a synonym for a handful of type class constraints that
are all straightforward boilerplate.  (defining constraint-synonyms
like this requires the `ConstraintKinds` extension, and it's a handy
trick to know).

The other constraint we need to satisfy is `DataSource`, which is
defined like this:

```haskell
class (DataSourceName req, StateKey req, Show1 req)
       => DataSource u req where
  fetch
    :: State req
    -> Flags
    -> u
    -> [BlockedFetch req]
    -> PerformFetch
```

`DataSource` has a single method, `fetch`, which is used by Haxl to
execute requests for this data source.  The key point is that `fetch`
is passed a list of `BlockedFetch` values, each of which contains
a single request.  The `BlockedFetch` type is defined like this:

```haskell
data BlockedFetch r = forall a. BlockedFetch (r a) (ResultVar a)
```

That is, it contains a request of type `r a`, and a `ResultVar a`
which is a container to store the result in.  The `fetch`
implementation can store the result using one of these two functions:

```haskell
putSuccess :: ResultVar a -> a -> IO ()
putFailure :: (Exception e) => ResultVar a -> e -> IO ()
```

Because `fetch` is passed a *list* of `BlockedFetch`, it can collect
together requests and satisfy them using a single query to the
database, or perform them concurrently, or use whatever methods are
available for performing multiple requests simultaneously.

The `fetch` method returns `PerformFetch`, which is defined like this:

```haskell
data PerformFetch
  = SyncFetch  (IO ())
  | AsyncFetch (IO () -> IO ())
```

For our purposes here, we'll only use `SyncFetch`, which should contain an
`IO` action whose job it is to fill in all the results in the
`BlockedFetch`es before it returns.  The alternative `AsyncFetch` can
be used to overlap requests from multiple data sources.

Lastly, let's talk about state.  Most data sources will need some
state; in the case of our blog database we need to keep track of the
handle to the database so that we don't have to open a fresh one each
time we make some queries.  In Haxl, data source state is represented
using an associated data type called `State`, which is defined by the
`StateKey` class:

```haskell
class Typeable f => StateKey (f :: * -> *) where
  data State f
```

So every data source with request type `req` defines a state of type
`State req`, which can of course be empty if the data source doesn't
need any state.  Our blog data source defines it like this:

```haskell
instance StateKey BlogRequest where
  data State BlogRequest = BlogDataState SQLiteHandle
```

The `State req` for a data source is passed to `fetch` each time it is
called.

The full implementation of our example data source is in <a
href="https://github.com/simonmar/haskell-eXchange-2015/blob/3ae0e34a051201eb77721bee2e940ec1f764a0df/BlogDataSource.hs">BlogDataSource.hs</a>.

## How do we run some Haxl?

There's a `runHaxl` function:

```haskell
runHaxl :: Env u -> GenHaxl u a -> IO a
```

Which needs something of type `Env u`.  This is the "environment" that
a Haxl computation runs in, and contains various things needed by the
framework.  It also contains the data source state, and to build an
`Env` we need to supply the initial state.  Here's how to get an `Env`:

```haskell
initEnv :: StateStore -> u -> IO (Env u)
```

The `StateStore` contains the states for all the data sources we're
using.  It is constructed with these two functions:

```haskell
stateEmpty :: StateStore
stateSet :: StateKey f => State f -> StateStore -> StateStore
```

To see how to put these together, take a look at <a
href="https://github.com/simonmar/haskell-eXchange-2015/blob/3ae0e34a051201eb77721bee2e940ec1f764a0df/HaxlBlog.hs">HaxlBlog.hs</a>.

## Trying it out

We saw a small example of our Haxl data source working earlier, but
just to round off this first part of the series and whet your appetite
for the next part, here are a couple more examples.

Haxl batches things together when we use the `Applicative` operators:

```
*HaxlBlog> run $ (,) <$> getPostContent 1 <*> getPostContent 2
select postid,content from postcontent where postid in (2,1)
("example content 1","example content 2")
```

Even if we have multiple `mapM` calls, they get batched together:


```
*HaxlBlog> run $ (,) <$> mapM getPostContent [1..3] <*> mapM getPostContent [4..6]
select postid,content from postcontent where postid in (6,5,4,3,2,1)
(["example content 1","example content 2","example content 3"],["example content 4","example content 5","example content 6"])
```

In Part 2 we'll talk more about batching, and introduce the upcoming
`ApplicativeDo` extension which will allow Haxl to automatically
parallelize sequential-looking `do`-expressions.
