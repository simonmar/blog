---
layout: page
title: '<a href="http://simonmar.github.io/bib/papers/monad-par.pdf">A Monad for Deterministic Parallelism</a>'
description: ""
category: publications
tags: []
---
(Simon Marlow, Ryan Newton, Simon Peyton Jones) *Haskell '11: Proceedings of the Fourth ACM SIGPLAN Symposium on Haskell*, Tokyo, Japan, ACM, 2011 <a href="monad-par-2011.bib">BibTeX</a>

We present a new programming model for deterministic parallel
computation in a pure functional language.  The model is monadic and
has explicit granularity, but allows dynamic construction of dataflow
networks that are scheduled at runtime, while remaining deterministic
and pure.  The implementation is based on monadic concurrency, which
has until now only been used to simulate concurrency in functional
languages, rather than to provide parallelism.  We present the API
with its semantics, and argue that parallel execution is
deterministic.  Furthermore, we present a complete work-stealing
scheduler implemented as a Haskell library, and we show that it
performs at least as well as the existing parallel programming models
in Haskell.
