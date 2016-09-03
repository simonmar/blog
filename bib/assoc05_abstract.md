---
layout: page
title: '<a href="http://simonmar.github.io/bib/papers/assoc.pdf">Associated types with class</a>'
description: ""
category: publications
tags: []
---
(Manuel M. T. Chakravarty, Gabriele Keller, Simon Peyton Jones, Simon Marlow) *POPL '05: Proceedings of the 32nd ACM SIGPLAN-SIGACT sysposium on Principles of programming languages*, pages 1--13, Long Beach, California, USA, ACM Press, 2005 <a href="assoc05.bib">BibTeX</a>

Haskell's type classes allow ad-hoc overloading, or typeindexing,
of functions. A natural generalisation is to allow
type-indexing of data types as well. It turns out that this
idea directly supports a powerful form of abstraction called
associated types, which are available in C++ using traits
classes. Associated types are useful in many applications,
especially for self-optimising libraries that adapt their data
representations and algorithms in a type-directed manner.

In this paper, we introduce and motivate associated types
as a rather natural generalisation of Haskell's existing type
classes. Formally, we present a type system that includes
a type-directed translation into an explicitly typed target
language akin to System F; the existence of this translation
ensures that the addition of associated data types to an
existing Haskell compiler only requires changes to the front
end.
