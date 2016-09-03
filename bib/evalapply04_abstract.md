---
layout: page
title: '<a href="http://simonmar.github.io/bib/papers/eval-apply.pdf">Making a fast curry: push/enter vs. eval/apply for higher-order languages</a>'
description: ""
category: publications
tags: []
---
(Simon Marlow, Simon Peyton Jones) *ICFP'04: Proceedings of the ACM SIGPLAN 2004 International Conference on Functional Programming*, pages 4--15, ACM Press, 2004 <a href="evalapply04.bib">BibTeX</a>

Higher-order languages that encourage currying are implemented using
one of two basic evaluation models: push/enter or
eval/apply. Implementors use their intuition and qualitative
judgements to choose one model or the other.Our goal in this paper is
to provide, for the first time, a more substantial basis for this
choice, based on our qualitative and quantitative experience of
implementing both models in a state-of-the-art compiler for
Haskell.Our conclusion is simple, and contradicts our initial
intuition: compiled implementations should use eval/apply.
