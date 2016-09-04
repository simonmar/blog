---
layout: page
title: 'Making a fast curry: push/enter vs. eval/apply for higher-order languages'
description: ""
category: publications
tags: []
---
(Simon Marlow, Simon Peyton Jones) *Journal of Functional Programming*, 16(4--5):415--449, July 2006

<a href="http://simonmar.github.io/bib/papers/evalapplyjfp06.pdf">Full Paper</a> | <a href="evalapplyjfp06.bib">BibTeX</a>

Higher-order languages that encourage currying are typically implemented using one of
two basic evaluation models: push/enter or eval/apply.   Implementors 
use their intuition and qualitative judgements 
to choose one model or the other.  

Our goal in this paper is to provide, for the first time, a more
substantial basis for this choice, based on our qualitative and
quantitative experience of implementing both models in a
state-of-the-art compiler for Haskell.

Our conclusion is simple, and contradicts our initial intuition: 
compiled implementations should use eval/apply.
