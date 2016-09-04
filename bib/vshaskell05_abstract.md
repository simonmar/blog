---
layout: page
title: 'Visual {H}askell: A full-featured {H}askell development environment'
description: ""
category: publications
tags: []
---
(Krasimir Angelov, Simon Marlow) *Haskell '05: Proceedings of the 2005 ACM SIGPLAN workshop on Haskell*, pages 5--16, Tallinn, Estonia, ACM Press, September 2005

<a href="http://simonmar.github.io/bib/papers/vshaskell.pdf">Full Paper</a> | <a href="vshaskell05.bib">BibTeX</a>

We describe the design and implementation of a full-featured Haskell
development environment, based on Microosft's extensible Visual Studio
environment.

Visual Haskell provides a number of features not found in existing
Haskell development environments: interactive error-checking,
displaying of inferred types in the editor, and other features based
on static properties of the source code.  Visual Haskell also provides
full support for developing and building multi-module Haskell projects,
based on the Cabal architecture.  Visual Haskell supports the full GHC
language, and can be used to develop real Haskell applications
(including the code of the plugin itself).

Visual Haskell has driven developments in other Haskell-related
projects: Cabal, the Concurrent FFI extension, and an API to allow
programmatic access to GHC itself.  Furthermore, development of the
Visual Haskell plugin required industrial-strength foreign language
interoperability; we describe all our experiences in detail.
