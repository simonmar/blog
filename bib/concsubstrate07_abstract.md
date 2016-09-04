---
layout: page
title: 'Lightweight concurrency primitives for GHC'
description: ""
category: publications
tags: []
---
(Peng Li, Simon Marlow, Simon Peyton Jones, Andrew Tolmach) Haskell '07: Proceedings of the ACM SIGPLAN workshop on Haskell workshop, pages 107--118, Freiburg, Germany, ACM, June 2007

<a href="http://simonmar.github.io/bib/papers/conc-substrate.pdf">Full Paper</a> | <a href="concsubstrate07.bib">BibTeX</a>

The Glasgow Haskell Compiler (GHC) has quite sophisticated support
for concurrency in its runtime system, which is written in low-level
C code.  As GHC evolves, the runtime system becomes increasingly
complex, error-prone, difficult to maintain and difficult to add new
concurrency features.

This paper presents an alternative approach to implement concurrency
in GHC.  Rather than hard-wiring all kinds of concurrency features,
the runtime system is a thin substrate providing only a small set of
concurrency primitives, and the rest of concurrency features are
implemented in software libraries written in Haskell.  This design
improves the safety of concurrency support; it also provides more
customizability of concurrency features, as new concurrency features
can be developed as Haskell library packages and deployed modularly.
