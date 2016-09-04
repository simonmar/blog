---
layout: page
title: 'Writing High-Performance Server Applications in {H}askell, Case Study: A {H}askell Web Server'
description: ""
category: publications
tags: []
---
(Simon Marlow) *Haskell Workshop*, Montreal, Canada, September 2000

| <a href="webserver00.bib">BibTeX</a>

Server applications, and in particular network-based server
applications, place a unique combination of demands on a programming
language: lightweight concurrency, high I/O throughput, and fault
tolerance are all important.

This paper describes a prototype web server written in Concurrent
Haskell (with extensions), and presents two useful results: firstly, a
conforming server could be written with minimal effort, leading to an
implementation in less than 1500 lines of code, and secondly the naive
implementation produced reasonable performance.  Furthermore, making
minor modifications to a few time-critical components improved
performance to a level acceptable for anything but the most heavily
loaded web servers.
