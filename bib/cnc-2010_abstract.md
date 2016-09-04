---
layout: page
title: 'Intel Concurrent Collections for {H}askell'
description: ""
category: publications
tags: []
---
(Ryan Newton, Chih-Ping Chen, Simon Marlow) (unpublished), 2010

<a href="http://simonmar.github.io/bib/papers/haskell_cnc_draft_submission.pdf">Full Paper</a> | <a href="cnc-2010.bib">BibTeX</a>

Intel Concurrent Collections (CnC) is a parallel programming
model in which a network of steps (functions) communicate
through message-passing as well as a limited form of shared memory.
This paper describes a new implementation of CnC for Haskell.
Compared to existing parallel programming models for Haskell,
CnC occupies a useful point in the design space: pure and deterministic
like Strategies, but more explicit about granularity and
the structure of the computation, which affords the programmer
greater control over parallel performance. We present results on 4,
32, and 48-core machines demonstrating parallel speedups ranging
between 7X and 22X on non-trivial benchmarks.
