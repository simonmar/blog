---
layout: page
title: 'Parallel Performance Tuning for {H}askell'
description: ""
category: publications
tags: []
---
(Don Jones Jr., Simon Marlow, Satnam Singh) *Haskell '09: Proceedings of the Second ACM SIGPLAN Symposium on Haskell*, Edinburgh, Scotland, ACM, 2009

<a href="http://simonmar.github.io/bib/papers/threadscope.pdf">Full Paper</a> | <a href="threadscope-09.bib">BibTeX</a>

Parallel Haskell programming has entered the mainstream with support
now included in GHC for multiple parallel programming models, along
with multicore execution support in the runtime.  However, tuning
programs for parallelism is still something of a black art.  Without
much in the way of feedback provided by the runtime system, it is a
matter of trial and error combined with experience to achieve good
parallel speedups.

This paper describes an early prototype of a parallel profiling system
for multicore programming with GHC.  The system comprises three parts:
fast event tracing in the runtime, a Haskell library for reading the
resulting trace files, and a number of tools built on this library for
presenting the information to the programmer.  We focus on one tool in
particular, a graphical timeline browser called ThreadScope.

The paper illustrates the use of ThreadScope through a number of case
studies, and describes some useful methodologies for parallelizing
Haskell programs.
