---
layout: page
title: 'Asynchronous exceptions in {H}askell'
description: ""
category: publications
tags: []
---
(Simon Marlow, Simon Peyton Jones, Andrew Moran, John Reppy) *PLDI '01: Proceedings of the ACM SIGPLAN 2001 conference on Programming language design and implementation*, pages 274--285, Snowbird, Utah, United States, ACM Press, 2001

<a href="http://simonmar.github.io/bib/papers/async.pdf">Full Paper</a> | <a href="async01.bib">BibTeX</a>

Asynchronous exceptions, such as timeouts, are important for
robust, modular programs, but are extremely difficult to program with
--- so much so that most programming languages either heavily restrict
them or ban them altogether.  We extend our earlier work, in which we
added synchronous exceptions to Haskell, to support asynchronous
exceptions too.  Our design introduces scoped combinators for blocking
and unblocking asynchronous interrupts, along with a somewhat
surprising semantics for operations that can suspend.  We give a
formal semantics for our system, along with the first steps towards a
theory that enables us to prove program properties.  Using our
primitives we can define combinators that support (for example) robust
access to shared data; and using the theory we can prove that they
have no race conditions, regardless of the behaviour of the program's
environment.  Shazam!
