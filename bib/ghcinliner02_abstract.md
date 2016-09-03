---
layout: page
title: '<a href="http://simonmar.github.io/bib/papers/inline.pdf">Secrets of the Glasgow {H}askell Compiler inliner</a>'
description: ""
category: publications
tags: []
---
(Simon Peyton Jones, Simon Marlow) *Journal of Functional Programming*, 12(4+5):393--434, July 2002 <a href="ghcinliner02.bib">BibTeX</a>

Higher-order languages, such as Haskell, encourage the programmer to
build abstractions by composing functions.  A good compiler must
inline many of these calls to recover an efficiently executable
program.

In principle, inlining is dead simple: just replace the call of
a function by an instance of its body.  But any compiler-writer will
tell you that inlining is a black art, full of delicate compromises
that work together to give good performance without unnecessary code bloat.

The purpose of this paper is, therefore, to articulate the key lessons
we learned from a full-scale ``production'' inliner, the one used in
the Glasgow Haskell compiler.  We focus mainly on the algorithmic
aspects, but we also provide some indicative measurements to
substantiate the importance of various aspects of the inliner.
