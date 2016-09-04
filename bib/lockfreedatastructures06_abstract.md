---
layout: page
title: 'Lock Free Data Structures using STMs in {H}askell'
description: ""
category: publications
tags: []
---
(Anthony Discolo, Tim Harris, Simon Marlow, Simon Peyton Jones, Satnam Singh) *FLOPS 2006: Eighth International Symposium on Functional and Logic Programming*, Fuji Susono, JAPAN, April 2006

<a href="http://simonmar.github.io/bib/papers/lockfreedatastructures.pdf">Full Paper</a> | <a href="lockfreedatastructures06.bib">BibTeX</a>

This paper explores the feasibility of re-expressing concurrent
algorithms with explicit locks in terms of lock free code written
using Haskell's implementation of software transactional
memory. Experimental results are presented which show that for
multi-processor systems the simpler lock free implementations offer
superior performance when compared to their corresponding lock based
implementations.
