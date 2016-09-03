---
layout: page
title: '<a href="http://simonmar.github.io/bib/papers/ExploringBarrierToEntry.pdf">Exploring the Barrier to Entry: Incremental Generational Garbage Collection for {H}askell</a>'
description: ""
category: publications
tags: []
---
(A.M. Cheadle, A.J. Field, S. Marlow, S.L. Peyton Jones, R.L. While) *International Symposium on Memory Management*, ACM, October 2004 <a href="exploringbarrier04.bib">BibTeX</a>

We document the design and implementation of a "production"
incremental garbage collector for GHC 6.02. It builds
on our earlier work (Non-stop Haskell) that exploited GHC's
dynamic dispatch mechanism to hijack object code pointers
so that objects in to-space automatically scavenge themselves
when the mutator attempts to \enter" them. This
paper details various optimisations based on code specialisation
that remove the dynamic space, and associated time,
overheads that accompanied our earlier scheme. We detail
important implementation issues and provide a detailed
evaluation of a range of design alternatives in comparison
with Non-stop Haskell and GHC's current generational collector.
We also show how the same code specialisation techniques
can be used to eliminate the write barrier in a generational
collector.
