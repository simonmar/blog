---
layout: page
title: '<a href="http://simonmar.github.io/bib/papers/local-gc.pdf">Multicore Garbage Collection with Local Heaps</a>'
description: ""
category: publications
tags: []
---
(Simon Marlow, Simon Peyton Jones) *ISMM '11: Proceedings of the 10th International Symposium on Memory Management*, San Jose, California, ACM, June 2011 <a href="local-gc-2011.bib">BibTeX</a>

In a parallel, shared-memory, language with a garbage collected heap,
it is desirable for each processor to perform minor garbage
collections independently. Although obvious, it is difficult to make
this idea pay off in practice, especially in languages where mutation
is common.  We present several techniques that substantially improve
the state of the art. We describe these techniques in the context of a
full-scale implementation of Haskell, and demonstrate that our
local-heap collector substantially improves scaling, peak performance,
and robustness.
