---
layout: post
title: Haskell in the Datacentre
description: ""
category: haxl
tags: [haxl]
---

At Facebook we run Haskell on thousands of servers, together handling
over a million requests per second.  Obviously we'd like to make the
most efficient use of hardware and get the most throughput per server
that we can.  So how do you tune a Haskell-based server to run well?

Over the past few months we've been tuning our server to squeeze out
as much performance as we can per machine, and this has involved
changes throughout the stack.  In this post I'll tell you about some
changes we made to GHC's runtime scheduler.

## Summary

We made one primary change: GHC's runtime is based around an M:N
threading model which is designed to map a large number (M) of
lightweight Haskell threads onto a small number (N) of heavyweight OS
threads.  In our application M is fixed and not all that big: we can
max out a server's resources when M is about 3-4x the number of
cores, and meanwhile setting N to the number of cores wasn't enough to
let us use all the CPU (I'll explain why shortly).

To cut to the chase, we ended up increasing N to be the same as M (or
close to it), and this bought us an extra 10-20% throughput per
machine.  It wasn't as simple as just setting some command-line
options, because GHC's garbage collector is designed to run with N
equal to the number of cores, so I had to make some changes to the way
GHC schedules things to make this work.

All these improvements are <a
href="https://phabricator.haskell.org/rGHC76ee260778991367b8dbf07ecf7afd31f826c824">upstream
<a
href="https://phabricator.haskell.org/rGHCf703fd6b50f0ae58bc5f5ddb927a2ce28eeaddf6">in</a>
<a
href="https://phabricator.haskell.org/rGHCe68195a96529cf1cc2d9cc6a9bc05183fce5ecea">GHC</a>,
and they'll be available in GHC 8.2.1, due early 2017.

## Background: Capabilities

When the GHC runtime starts, it creates a number of *capabilities*
(also sometimes called HEC, for Haskell Execution Context).  The
number of capabilities is determined by the `-N` flag when you start
the Haskell program, e.g. `prog +RTS -N4` would run `prog` with 4
capabilities.

A capability is the *ability to run Haskell code*.  It consists of
an allocation area (also called *nursery*) for allocating memory, a
queue of lightweight Haskell threads to run, and one or more OS
threads (called *workers*) that will run the Haskell code.  Each
capability can run a single Haskell thread at a time; if the Haskell
thread blocks, the next Haskell thread in the queue runs, and so on.

Typically we choose the number of capabilities to be equal to the
number of physical cores on the machine.  This makes sense: there is
no advantage in trying to run more Haskell threads simultaneously than
we have physical cores.

## How our server maps onto this

Our system is based on the C++ Thrift server, which provides a fixed
set of worker threads that pull requests from a queue and execute
them.  We choose the number of worker threads to be high enough that
we can fully utilize the server, but not too high that we create too
much contention and increase latency under maximum load.

Each worker thread calls into Haskell via a `foreign export` to do the
actual work.  The GHC runtime then chooses a capability to run the
call.  It normally picks an idle capability, and the call executes
immediately.  If there are no idle capabilities, the call blocks on
the queue of a capability until the capability yields control to it.

## The problem

At high load, even though we have enough threads to fully utilize the
CPU cores, the intermediate layer of scheduling where GHC assigns
threads to capabilities means that we sometimes have threads idle that
could be running.  Sometimes there are multiple runnable
workers on one capability while other capabilities are idle, and the
runtime takes a little while to load-balance during which time we're
not using all the available CPU capacity.

Meanwhile the kernel is doing its own scheduling, trying to map those
OS threads onto CPUs.  Obviously the kernel has a rather more
sophisticated scheduler than GHC and could do a better job of mapping
those M threads onto its N cores, but we aren't letting it.  In this
scenario, the extra layer of scheduling in GHC is just a drag on
performance.

## First up, a bug in the load-balancer.

While investigating this I found a <a href="https://phabricator.haskell.org/rGHC1fa92ca9b1ed4cf44e2745830c9e9ccc2bee12d5">bug in the way GHC's load-balancing
worked</a> - it could cause a large number of spurious wakeups of other
capabilities while load-balancing.  Fixing this was worth a few
percent right away, but I had my sights set on larger gains.

## Couldn't we just increase the number of capabilities?

Well yes, and of course we tried just bumping up the `-N` value, but
increasing `-N` beyond the number of cores just tends to increase CPU
usage without increasing throughput.

Why? Well, the problem is the garbage collector.  The GC keeps all its
threads running trying to steal work from each other, and when we have
more threads than we have real cores, the spinning threads are
slowing down the threads doing the actual work.

## Increasing the number of capabilities without slowing down GC

What we'd like to do is to have a larger set of mutator threads, but
only use a subset of those when it's time to GC.  That's exactly what
this new flag does:

```
+RTS -qn<threads>
```

For example, on a 24-core machine you might use `+RTS -N48 -qn24` to
have 48 mutator threads, but only 24 threads during GC.  This is great
for using hyperthreads too, because hyperthreads work well for the
mutator but not for the GC.

Which threads does the runtime choose to do the GC?  The scheduler has
a heuristic which looks at which capabilities are currently inactive
and chooses those to be idle, to avoid having to synchronise with
threads that are currently asleep.

### `+RTS -qn` will now be turned on by default!

This is a slight digression, but it turns out that setting `+RTS -qn`
to the number of CPU cores is always a good idea if `-N` is too large.
So the runtime will be <a
href="https://phabricator.haskell.org/rGHC6c47f2efa3f8f4639f375d34f54c01a60c9a1a82">doing
this by default from now on</a>.  If `-N` accidentally gets set too
large, performance won't drop quite so badly as it did with GHC 8.0
and earlier.

## Capability affinity

Now we can safely increase the number of capabilities well beyond the
number of real cores, provided we set a smaller number of GC threads
with `+RTS -qn`.

The final step that we took in Sigma is to map our server threads 1:1
with capabilities.  When the C++ server thread calls into Haskell,
it immediately gets a capability, there's never any blocking, and nor
does the GHC runtime need to do any load-balancing.

How is this done?  There's a new C API exposed by the RTS:

```
void rts_setInCallCapability (int preferred_capability, int affinity);
```

In each thread you call this to map that thread to a particular
capability.  For example you might call it like this:

```
static std::atomic<int> counter;
...
rts_setInCallCapability(counter.fetch_add(1), 0);
```

And ensure that you call this once per thread.  The ``affinity``
argument is for binding a thread to a CPU core, which might be useful
if you're also using GHC's affinity setting (`+RTS -qa`).  In our case
we haven't found this to be useful.

## Future

You might be thinking, *but isn't the great thing about Haskell
that we have lightweight threads?*  Yes, absolutely.  We do make
use of lightweight threads in our system, but the main server threads
that we inherit from the C++ Thrift server are heavyweight OS threads.

Fortunately in our case we can fully load the system with 3-4
heavyweight threads per core, and this solution works nicely with the
constraints of our platform.  But if the ratio of I/O waiting to CPU
work in our workload increased, we would need more threads per core to
keep the CPU busy, and the balance tips towards wanting lightweight
threads.  Furthermore, using lightweight threads would make the system
more resilient to increases in latency from downstream services.

In the future we'll probably move to lightweight threads, but in the
meantime these changes to scheduling mean that we can squeeze all the
available throughput from the existing architecture.
