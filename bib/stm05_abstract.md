---
layout: page
title: '<a href="http://simonmar.github.io/bib/papers/stm.pdf">Composable Memory Transactions</a>'
description: ""
category: publications
tags: []
---
(Tim Harris, Simon Marlow, Simon Peyton Jones, Maurice Herlihy) *PPoPP'05: ACM SIGPLAN Symposium on Principles and Practice of Parallel Programming*, Chicago, Illinois, June 2005 <a href="stm05.bib">BibTeX</a>

Writing concurrent programs is notoriously difficult, and is of
increasing practical importance.  A particular source of concern
is that even correctly-implemented concurrency abstractions cannot
be composed together to form larger abstractions.  In this paper
we present a new concurrency model, based on \emph{transactional memory},
that offers far richer composition.  All the usual benefits of transactional memory
are present (e.g. freedom from deadlock), but in addition we describe
new modular forms of \emph{blocking} and \emph{choice} that
have been inaccessible in earlier work.
