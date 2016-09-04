---
layout: page
title: 'Parallel Generational-Copying Garbage Collection with a Block-Structured Heap'
description: ""
category: publications
tags: []
---
(Simon Marlow, Tim Harris, Roshan P. James, Simon Peyton Jones) *ISMM '08: Proceedings of the 7th international symposium on Memory management*, Tucson, Arizona, ACM, June 2008

<a href="http://simonmar.github.io/bib/papers/parallel-gc.pdf">Full Paper</a> | <a href="parallel-gc-08.bib">BibTeX</a>

We present a parallel generational-copying garbage collector
implemented for the Glasgow Haskell Compiler.  We use a
block-structured memory allocator, which provides a natural
granularity for dividing the work of GC between many threads, leading
to a simple yet effective method for parallelising copying GC.  The
results are encouraging: we demonstrate wall-clock speedups of on
average a factor of 2 in GC time on a commodity 4-core machine with no
programmer intervention, compared to our best sequential GC.
