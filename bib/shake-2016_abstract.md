---
layout: page
title: 'Non-recursive Make Considered Harmful: Build Systems at Scale'
description: ""
category: publications
tags: []
---
(Andrey Mokhov, Neil Mitchell, Simon Peyton Jones, Simon Marlow) *Proceedings of the 9th International Symposium on Haskell*, pages 170--181, Nara, Japan, ACM, 2016

<a href="http://simonmar.github.io/bib/papers/shake.pdf">Full Paper</a> | <a href="shake-2016.bib">BibTeX</a>

Most build systems start small and simple, but over time grow
into hairy monsters that few dare to touch. As we demonstrate in
this paper, there are a few issues that cause build systems major
scalability challenges, and many pervasively used build systems
(e.g. Make) do not scale well.

This paper presents a solution to the challenges we identify.  We use
functional programming to design abstractions for build systems, and
implement them on top of the Shake library, which allows us to
describe build rules and dependencies. To substantiate our claims, we
engineer a new build system for the Glasgow Haskell Compiler. The
result is more scalable, faster, and spectacularly more maintainable
than its Make-based predecessor.
