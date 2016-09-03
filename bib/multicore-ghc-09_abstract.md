---
layout: page
title: '<a href="http://simonmar.github.io/bib/papers/multicore-ghc.pdf">Runtime Support for Multicore {H}askell</a>'
description: ""
category: publications
tags: []
---
(Simon Marlow, Simon Peyton Jones, Satnam Singh) *ICFP '09: Proceeding of the 14th ACM SIGPLAN International Conference on Functional Programming*, Edinburgh, Scotland, August 2009 <a href="multicore-ghc-09.bib">BibTeX</a>

Purely functional programs should run well on parallel hardware
because of the absence of side effects, but it has proved hard to
realise this potential in practice.  Plenty of papers describe
promising ideas, but vastly fewer describe real implementations with
good wall-clock performance.  We describe just such an implementation,
and quantitatively explore some of the complex design tradeoffs that
make such implementations hard to build.  Our measurements are
necessarily detailed and specific, but they are reproducible, and we
believe that they offer some general insights.
