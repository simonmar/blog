---
layout: page
title: 'Composable scheduler activations for Haskell'
description: ""
category: publications
tags: []
---
(K. C. Sivaramakrishnan, Tim Harris, Simon Marlow, Simon Peyton Jones) *Journal of Functional Programming*, 26, pages e9 (39 pages), 2016

<a href="http://simonmar.github.io/bib/papers/composable_scheduler_activations.pdf">Full Paper</a> | <a href="composable_scheduler_activations-2016.bib">BibTeX</a>

The runtime for a modern, concurrent, garbage collected language like
Java or Haskell is like an operating system: sophisticated, complex,
performant, but alas very hard to change.  If more of the runtime
system were in the high-level language, it would be far more modular
and malleable. In this paper, we describe a novel concurrency
substrate design for the Glasgow Haskell Compiler that allows
multicore schedulers for concurrent and parallel Haskell programs to
be safely and modularly described as libraries in Haskell. The
approach relies on abstracting the interface to the user-implemented
schedulers through scheduler activations, together with the use of
Software Transactional Memory to promote safety in a multicore
context.
