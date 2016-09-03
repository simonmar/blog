---
layout: page
title: '<a href="http://simonmar.github.io/bib/papers/multiproc.pdf">{H}askell on a Shared-Memory Multiprocessor</a>'
description: ""
category: publications
tags: []
---
(Tim Harris, Simon Marlow, Simon Peyton Jones) *Haskell '05: Proceedings of the 2005 ACM SIGPLAN workshop on Haskell*, pages 49--61, Tallinn, Estonia, ACM Press, September 2005 <a href="multiproc05.bib">BibTeX</a>

Multi-core processors are coming, and we need ways to program them.
The combination of purely-functional programming and explicit, monadic threads,
communicating using transactional memory, looks like a particularly promising
way to do so.  This paper describes a full-scale implementation of shared-memory
parallel Haskell, based on the Glasgow Haskell Compiler.  Our main technical 
contribution is a lock-free mechanism for evaluating shared thunks that eliminates
the major performance bottleneck in parallel evaluation of a lazy language.
Our results are preliminary but promising: we can demonstrate wall-clock speedups 
of a serious application (GHC itself), even with only two processors, compared
to the same application compiled for a uni-processor.
