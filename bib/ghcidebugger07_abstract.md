---
layout: page
title: 'A Lightweight Interactive Debugger for {H}askell'
description: ""
category: publications
tags: []
---
(Simon Marlow, Jos'e Iborra, Bernard Pope, Andy Gill) Haskell '07: Proceedings of the ACM SIGPLAN workshop on Haskell workshop, pages 13--24, Freiburg, Germany, ACM, June 2007

<a href="http://simonmar.github.io/bib/papers/ghci-debug.pdf">Full Paper</a> | <a href="ghcidebugger07.bib">BibTeX</a>

This paper describes the design and construction of a Haskell
source-level debugger built into the GHCi interactive environment.  We
have taken a pragmatic approach: the debugger is based on the
traditional stop-examine-continue model of online debugging, which is
simple and intuitive, but has traditionally been shunned in the
context of Haskell because it exposes the lazy evaluation order.  We
argue that this drawback is not as severe as it may seem, and in some
cases is an advantage.

The design focusses on \emph{availability}: our debugger is intended
to work on all programs that can be compiled with GHC, and without
requiring the programmer to jump through additional hoops to debug
their program.  The debugger has a novel approach for reconstructing
the type of runtime values in a polymorphic context.  Our
implementation is light on complexity, and was integrated into GHC
without significant upheaval.
