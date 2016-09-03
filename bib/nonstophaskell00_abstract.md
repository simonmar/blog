---
layout: page
title: '<a href="http://simonmar.github.io/bib/papers/nonstop.pdf">Non-stop {H}askell</a>'
description: ""
category: publications
tags: []
---
(A. M. Cheadle, A. J. Field, S. Marlow, S. L. Peyton Jones, R. L. While) *ICFP '00: Proceedings of the fifth ACM SIGPLAN international conference on Functional programming*, pages 257--267, ACM Press, 2000 <a href="nonstophaskell00.bib">BibTeX</a>

We describe an efficient technique for incorporating Baker's
 incremental garbage collection algorithm into the Spineless Tagless
 G-machine on stock hardware. This algorithm eliminates the stop/go
 execution associated with bulk copying collection algorithms,
 allowing the system to place an upper bound on the pauses due to
 garbage collection. The technique exploits the fact that objects are
 always accessed by jumping to code rather than being explicitly
 dereferenced. It works by modifying the entry code-pointer when an
 object is in the transient state of being evacuated but not
 scavenged. An attempt to enter it from the mutator causes the object
 to "self-scavenge" transparently before resetting its entry code
 pointer. We describe an implementation of the scheme in v4.01 of the
 Glasgow Haskell Compiler and report performance results obtained by
 executing a range of applications. These experiments show that the
 read barrier can be implemented in dynamic dispatching systems such
 as the STG-machine with very short mutator pause times and with
 negligible overhead on execution time.
