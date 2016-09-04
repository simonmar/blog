---
layout: page
title: 'Desugaring Haskell''s Do-notation into Applicative Operations'
description: ""
category: publications
tags: []
---
(Simon Marlow, Simon Peyton Jones, Edward Kmett, Andrey Mokhov) *Proceedings of the 9th International Symposium on Haskell*, pages 92--104, Nara, Japan, ACM, 2016

<a href="http://simonmar.github.io/bib/papers/applicativedo.pdf">Full Paper</a> | <a href="applicativedo-2016.bib">BibTeX</a>

Monads have taken the world by storm, and are supported by
do-notation (at least in Haskell).  Programmers are increasingly
waking up to the usefulness and ubiquity of Applicatives, but they
have so far been hampered by the absence of supporting notation.  In
this paper we show how to re-use the very same do-notation to work
for Applicatives as well, providing efficiency benefits for some types
that are both Monad and Applicative, and syntactic convenience for
those that are merely Applicative.  The result is fully implemented
as an optional extension in GHC, and is in use at Facebook to make
it easy to write highly-parallel queries in a distributed system.
