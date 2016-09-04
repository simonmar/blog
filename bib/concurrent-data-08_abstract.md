---
layout: page
title: 'Comparing the performance of concurrent linked-list implementations in {H}askell'
description: ""
category: publications
tags: []
---
(Martin Sulzmann, Edmund S. L. Lam, Simon Marlow) *DAMP 2009: Workshop on Declarative Aspects of Multicore Programming*, Savannah, Georgia, USA, 2009

<a href="http://simonmar.github.io/bib/papers/concurrent-data.pdf">Full Paper</a> | <a href="concurrent-data-08.bib">BibTeX</a>

Haskell has a rich set of synchronization primitives for implementing
shared-state concurrency abstractions, ranging from the very high
level (Software Transactional Memory) to the very low level (mutable
variables with atomic read-modify-write).

In this paper we perform a systematic comparison of these different
concurrent programming models by using them to implement the same
abstraction: a concurrent linked-list.  Our results are somewhat
surprising: there is a full two orders of magnitude difference in
performance between the slowest and the fastest implementation.  Our
analysis of the performance results gives new insights into the
relative performance of the programming models and their
implementation.

Finally, we suggest the addition of a single primitive which in our
experiments improves the performance of one of the STM-based
implementations by more than a factor of 7.
