---
layout: post
title: "Indexing Hackage: Glean vs. hiedb"
description: ""
category: glean
tags: [glean]
---

I thought it might be fun to try to use Glean to index as much of
Hackage as I could, and then do some rough comparisons against <a
href="">hiedb</a> and also play around to see what interesting queries
we could run against a database of all the code in Hackage.

This project was mostly just for fun: Glean is not going to replace
`hiedb` any time soon, for reasons that will become clear. Neither are
we ready (yet) to build an HLS plugin that can use Glean, but
hopefully this at least demonstrates that such a thing should be
possible, and Glean might offer some advantages over `hiedb` in
performance and flexibility.

A bit of background:

* <a href="https://glean.software">Glean</a> is a code-indexing system
  that we developed at Meta. It's used internally at Meta for a wide
  range of use cases, including code browsing, documentation
  generation and code analysis. You can read about the ways in which
  Glean is used at Meta in <a
  href="https://engineering.fb.com/2024/12/19/developer-tools/glean-open-source-code-indexing/">Indexing
  Code At Scale with Glean</a>.

* <a href="https://github.com/wz1000/HieDb">hiedb</a> is a code-indexing system for Haskell. It takes
  the `.hie` files that GHC produces when given the option
  `-fwrite-ide-info` and writes the information to a SQLite database
  in various tables. The idea is that putting the information in a DB
  allows certain operations that an IDE needs to do, such as
  go-to-definition, to be fast.

You can think of Glean as a general-purpose system that does the same
job as `hiedb`, but for multiple languages and with a more flexible
data model. The open-source version of Glean comes with indexers for
<a href="https://glean.software/docs/indexer/intro/">ten languages or
so</a>, and moreover Glean supports <a
href="https://sourcegraph.com/blog/announcing-scip">SCIP</a> which has
indexers for various languages available from SourceGraph.

Since a `hiedb` is just a SQLite DB with a few tables, if you want you
can query it directly using SQL. However, most users will access the
data through either the command-line `hiedb` tool or through the API,
which provide the higher-level operations such as go-to-definition and
find-references. Glean has a similar setup: you can make raw queries
using Glean's query language (<a
href="https://glean.software/docs/angle/intro/">Angle</a>) using the
<a href="https://glean.software/docs/shell/">Glean shell</a> or the <a href="https://glean.software/docs/cli/">command-line tool</a>, while the higher-level
operations that know about symbols and references are provided by a
separate system called <a href="https://github.com/facebookincubator/Glean/tree/main/glean/glass">Glass</a> which also has a command-line tool and
API. In Glean the raw data is language-specific, while the Glass
interface provides a language-agnostic view of the data in a way
that's useful for tools that need to navigate or search code.

## An ulterior motive

In part all of this was an excuse to rewrite Glean's Haskell
indexer. We built a Haskell indexer a while ago but it's pretty
limited in what information it stores, only capturing enough
information to do go-to-definition and find-references and only for a
subset of identifiers. Furthermore the old indexer works by first
producing a `hiedb` and consuming that, which is both unnecessary and
limits the information we can collect. By processing the `.hie` files
directly we have access to richer information, and we don't have the
intermediate step of creating the `hiedb` which can be slow.

## The rest of this post

The rest of the post is organised as follows, feel free to jump
around:

* [Performance](#performance): a few results comparing `hiedb` with Glean on an
index of all of Hackage

* [Queries](#what-other-queries-can-we-do-with-glean): A couple of examples of queries we can do with
  a Glean index of Hackage: searching by name, and finding dead code.

* [Apparatus](#apparatus): more details on how I set
everything up and how it all works.

* [What's next](#whats-next): some thoughts on what we still need to add to
  the indexer.

# Performance

All of this was perfomed on a build of 2900+ packages from Hackage,
for more details see [Building all of Hackage](#building-all-of-hackage)
below.

## Indexing performance

I used this hiedb command:

```
hiedb index -D /tmp/hiedb . --skip-types
```

I'm using `--skip-types` because at the time of writing I haven't
implemented type indexing in Glean's Haskell indexer, so this should
hopefully give a more realistic comparison.

This was the Glean command:

```
glean --service localhost:1234 \
  index haskell-hie --db stackage/0 \
  --hie-indexer $(cabal list-bin hie-indexer) \
  ~/code/stackage/dist-newstyle/build/x86_64-linux/ghc-9.4.7 \
  --src '$PACKAGE'
```

Time to index:

* hiedb: 1021s
* Glean: 470s

I should note that in the case of Glean the only parallelism is
between the indexer and the server that is writing to the DB. We
didn't try to index multiple `.hie` files in parallel, although that
would be fairly trivial to do. I suspect `hiedb` is also
single-threaded just going by the CPU load during indexing.

## Size of the resulting DB

* hiedb: 5.2GB
* Glean: 0.8GB

It's quite possible that hiedb is simply storing more information, but
Glean does have a rather efficient storage system based on RocksDB.

## Performance of find-references

Let's look up all the references of `Data.Aeson.encode`:

```
hiedb -D /tmp/hiedb name-refs encode Data.Aeson
```

This is the query using Glass:

```
cabal run glass-democlient -- --service localhost:12345 \
  references stackage/hs/aeson/Data/Aeson/var/encode
```

This is the raw query using Glean:

```
glean --service localhost:1234 --db stackage/0 \
  '{ Refs.file, Refs.uses[..] } where Refs : hs.NameRefs; Refs.target.occ.name = "encode"; Refs.target.mod.name = "Data.Aeson"'
```

* `hiedb`: 2.3s
* `glean` (via Glass): 0.39s
* `glean` (raw query): 0.03s

(side note: `hiedb` found 416 references while Glean found 415. I
haven't yet checked where this discrepancy comes from.)

But these results don't really tell the whole story.

In the case of `hiedb`, `name-refs` does a full table scan so it's
going to take time proportional to the number of refs in the DB. Glean
meanwhile has indexed the references by name, so it can serve this
query very efficiently. The actual query takes a few milliseconds, the
main overhead is encoding and decoding the results.

The reason the Glass query takes longer than the raw Glean query is
because Glass also fetches additional information about each
reference, so it performs a lot more queries.

We can also do the raw `hiedb` query using the sqlite shell:

```
sqlite> select count(*) from refs where occ = "v:encode" AND mod = "Data.Aeson";
417
Run Time: real 2.038 user 1.213905 sys 0.823001
```

Of course `hiedb` could index the refs table to make this query much
faster, but it's interesting to note that Glean has already done that
and it was *still* quicker to index and produced a smaller DB.

## Performance of find-definition

Let's find the definition of `Data.Aeson.encode`, first with `hiedb`:

```
$ hiedb -D /tmp/hiedb name-def encode Data.Aeson
Data.Aeson:181:1-181:7
```

Now with Glass:

```
$ cabal run glass-democlient -- --service localhost:12345 \
  describe stackage/hs/aeson/Data/Aeson/var/encode
stackage@aeson-2.1.2.1/src/Data/Aeson.hs:181:1-181:47
```

(worth noting that `hiedb` is giving the span of the identifier only,
while Glass is giving the span of the whole definition. This is just a
different choice; the `.hie` file contains both.)

And the raw query using Glean:

```
$ glean --service localhost:1234 query --db stackage/0 --recursive \
  '{ Loc.file, Loc.span } where Loc : hs.DeclarationLocation; N : hs.Name; N.occ.name = "encode"; N.mod.name = "Data.Aeson"; Loc.name = N' | jq
{
  "id": 18328391,
  "key": {
    "tuplefield0": {
      "id": 9781189,
      "key": "aeson-2.1.2.1/src/Data/Aeson.hs"
    },
    "tuplefield1": {
      "start": 4136,
      "length": 46
    }
  }
}
```

Times:

* hiedb: 0.18s
* Glean (via Glass): 0.05s
* Glean (raw query): 0.01s

In fact there's a bit of overhead when using the Glean CLI, we can get a
better picture of the real query time using the shell:

```
stackage> { Loc.file, Loc.span } where Loc : hs.DeclarationLocation; N : hs.Name; N.occ.name = "encode"; N.mod.name = "Data.Aeson"; Loc.name = N
{
  "id": 18328391,
  "key": {
    "tuplefield0": { "id": 9781189, "key": "aeson-2.1.2.1/src/Data/Aeson.hs" },
    "tuplefield1": { "start": 4136, "length": 46 }
  }
}

1 results, 2 facts, 0.89ms, 696176 bytes, 2435 compiled bytes
```

The query itself takes less than 1ms.

Again, the issue with `hiedb` is that its data is not indexed in a way
that makes this query efficient: the `defs` table is indexed by the
pair `(hieFile,occ)` not `occ` alone. Interestingly, when the module
is known it ought to be possible to do a more efficient query with
`hiedb` by first looking up the `hieFile` and then using that to query
`defs`.

# What other queries can we do with Glean?

I'll look at a couple of examples here, but really the possibilities
are endless. We can collect whatever data we like from the `.hie`
file, and design the schema around whatever efficient queries we want
to support.

## Search by case-insensitive prefix

Let's search for all identifiers that start with the case-insensitive
prefix `"withasync"`:

```
$ glass-democlient --service localhost:12345 \
  search stackage/withasync -i | wc -l
55
```

In less than 0.1 seconds we find 55 such identifiers in Hackage. (the
output isn't very readable so I didn't include it here, but for
example this finds results not just in `async` but in a bunch of
packages that wrap `async` too).

Case-insensitive prefix search is supported by an index that Glean
produces when the DB is created. It works in the same way as efficient
find-references, more details on that [below](#how-does-it-work).

Why only prefix and not suffix or infix? What about fuzzy search? We
could certainly provide a suffix search too; infix gets more tricky
and it's not clear that Glean is the best tool to use for infix or
fuzzy text search: there are better data representations for that kind
of thing. Still, case-insensitive prefix search is a useful thing to
have.

Could we support Hoogle using Glean? Absolutely. That said, Hoogle
doesn't seem too slow. Also we need to index types in Glean before it
could be used for type search.

## Identify dead code

Dead code is, by definition, code that isn't used anywhere. We have a
handy way to find that: any identifier with no references isn't
used. But it's not *quite* that simple: we want to ignore references
in imports and exports, and from the type signature.

Admittedly finding unreferenced code within Hackage isn't all that
useful, because the libraries in Hackage are consumed by end-user code
that we haven't indexed so we can't see all the references. But you
could index your own project using Glean and use it to find dead
code. In fact, I did that for Glean itself and identified one entire
module that was dead, amongst a handful of other dead things.

Here's a query to find dead code:

```
N where
  N = hs.Name _;
  N.sort.external?;
  hs.ModuleSource { mod = N.mod, file = F };
  !(
    hs.NameRefs { target = N, file = RefFile, uses = R };
    RefFile != F;
    coderef = (R[..]).kind
  )
```

Without going into all the details, here's roughly how it works:

* `N = hs.Name _;` declares `N` to be a fact of `hs.Name`
* `N.sort.external?;` requires `N` to be external (i.e. exported), as
 opposed to a local variable
* `hs.ModuleSource { mod = N.mod, file = F };` finds the file `F`
  corresponding to this name's module
* The last part is checking to see that there are no references to
  this name that are (a) in a different file and (b) are in code,
  i.e. not import/export references. Restricting to other files isn't
  *exactly* what we want, but it's enough to exclude references from
  the type signature. Ideally we would be able to identify those more
  precisely (that's on the TODO list).

You can try this on Hackage and it will find a lot of stuff. It might
be useful to focus on particular modules to find things that aren't
used anywhere, for example I was interested in which identifiers in
`Control.Concurrent.Async` aren't used:

```
N where
  N = hs.Name _;
  N.mod.name = "Control.Concurrent.Async";
  N.mod.unit = "async-2.2.4-inplace";
  N.sort.external?;
  hs.ModuleSource { mod = N.mod, file = F };
  !(
    hs.NameRefs { target = N, file = RefFile, uses = R };
    RefFile != F;
    coderef = (R[..]).kind
  )
```

This finds 21 identifiers, which I can use to decide what to deprecate!

# Apparatus

## Building all of Hackage

The goal was to build as much of Hackage as possible and then to index
it using both `hiedb` and Glean, and see how they differ.

To avoid problems with dependency resolution, I used a Stackage LTS
snapshot of package versions. Using LTS-21.21 and GHC 9.4.7, I was
able to build 2922 packages. About 50 failed for some reason or other.

I used this `cabal.project` file:

```
packages: */*.cabal
import: https://www.stackage.org/lts-21.21/cabal.config

package *
    ghc-options: -fwrite-ide-info

tests: False
benchmarks: False

allow-newer: *
```

And did a large `cabal get` to fetch all the packages in LTS-21.21.

Then

```
cabal build all --keep-going
```

After a few retries to install any required RPMs to get the dependency
resolution phase to pass, and to delete a few packages that weren't
going to configure successfully, I went away for a few hours to let
the build complete.

It's entirely possible there's a better way to do this that I don't
know about - please let me know!

## Building Glean

The Haskell indexer I'm using is in <a
href="https://github.com/facebookincubator/Glean/pull/522">this pull
request</a> which at the time of writing isn't merged yet. (Since I've
left Meta I'm just a regular open-source contributor and have to wait
for my PRs to be merged just like everyone else!).

Admittedly Glean is not the easiest thing in the world to build,
mainly because it has a couple of troublesome dependencies:
[folly](https://github.com/facebook/folly) (Meta's library of
highly-optimised C++ utilities) and [RocksDB](https://rocksdb.org/).
Glean depends on a very up to date version of these libraries so we
can't use any distro packaged versions.

Full instructions for building Glean are
[here](https://glean.software/docs/building/) but roughly it goes like
this on Linux:

* Install a bunch of dependencies with `apt` or `yum`
* Build the C++ dependencies with `./install-deps.sh` and set some env vars
* `make`

The `Makefile` is needed because there are some codegen steps that
would be awkward to incorporate into the Cabal setup. After the first
`make` you can usually just switch to `cabal` for rebuilding stuff
unless you change something (e.g. a schema) that requires re-running
the codegen.

## Running Glean

I've done everything here with a running Glean server, which was
started like this:

```
cabal run exe:glean-server -- \
  --db-root /tmp/db \
  --port 1234 \
  --schema glean/schema/source
```

While it's possible to run Glean queries directly on the DB without a
server, running a server is the normal way because it avoids the
latency from opening the DB each time, and it keeps an in-memory cache
which significantly speeds up repeated queries.

The examples that use Glass were done using a running Glass server,
started like this:

```
cabal run glass-server -- --service localhost:1234 --port 12345
```

## How does it work?

The interesting part of the Haskell indexer is the schema in <a
href="https://github.com/facebookincubator/Glean/blob/8f49a6bfe1217657d19287d6d583b13c4a8154f8/glean/schema/source/hs.angle#L83">hs.angle</a>. Every
language that Glean indexes needs a schema, which describes the data
that the indexer will store in the DB. Unlike an SQL schema, a Glean
schema looks more like a set of datatype declarations, and it really
does correspond to a set of (code-generated) types that you can work
with when programmatically writing data, making queries, or inspecting
results. For more about Glean schemas, see <a
href="https://glean.software/docs/schema/basic/">the
documentation</a>.

Being able to design your own schema means that you can design
something that is a close match for the requirements of the language
you're indexing. In our Glean schema for Haskell, we use a `Name`,
`OccName`, and `Module` structure that's similar to the one GHC uses
internally and is stored in the `.hie` files.

The [indexer
itself](https://github.com/facebookincubator/Glean/blob/e523edae14657db4038df4f7676b0072baf268ed/glean/lang/haskell/HieIndexer/Index.hs)
just reads the `.hie` files and produces Glean data using datatypes
that are generated from the schema. For example, here's a fragment of
the indexer that produces `Module` facts, which contain a `ModuleName`
and a `UnitName`:

```haskell
mkModule :: Glean.NewFact m => GHC.Module -> m Hs.Module
mkModule mod = do
  modname <- Glean.makeFact @Hs.ModuleName $
    fsToText (GHC.moduleNameFS (GHC.moduleName mod))
  unitname <- Glean.makeFact @Hs.UnitName $
    fsToText (unitFS (GHC.moduleUnit mod))
  Glean.makeFact @Hs.Module $
    Hs.Module_key modname unitname
```

Also interesting is how we support fast find-references. This is
done using a [stored derived
predicate](https://glean.software/docs/derived/#stored-derived-predicates)
in the schema:

```
predicate NameRefs:
  {
    target: Name,
    file: src.File,
    uses: [src.ByteSpan]
  } stored {Name, File, Uses} where
  FileXRefs {file = File, refs = Refs};
  {name = Name, spans = Uses} = Refs[..];
```

here `NameRefs` is a predicate---which you can think of as a datatype,
or a table in SQL---defined in terms of another predicate,
`FileXRefs`. The facts of the predicate `NameRefs` (rows of the table)
are derived automatically using this definition when the DB is
created. If you're familiar with SQL, a stored derived predicate in
Glean is rather like a materialized view in SQL.

# What's next?

As I mentioned earlier, the indexer doesn't yet index types, so that
would be an obvious next step. There are a handful of weird corner
cases that aren't handled correctly, particularly around record
selectors, and it would be good to iron those out.

Longer term ideally the Glean data would be rich enough to produce the
Haddock docs. In fact Meta's internal code browser does produce
documentation on the fly from Glean data for some languages - Hack and
C++ in particular. Doing it for Haskell is a bit tricky because while
I believe the `.hie` file does contain enough information to do this,
it's not easy to reconstruct the full ASTs for declarations. Doing it
by running the compiler---perhaps using the Haddock API---would be
an option, but that involves a deeper integration with Cabal so it's
somewhat more awkward to go that route.

Could HLS use Glean? Perhaps it would be useful to have a full Hackage
index to be able to go-to-definition from library references? As a
plugin this might make sense, but there are a lot of things to fix and
polish before it's really practical.

Longer term should we be thinking about replacing hiedb with Glean?
Again, we're some way off from that. The issue of incremental updates
is an interesting one - Glean does support [incremental
indexing](https://glean.software/docs/implementation/incrementality/)
but so far it's been aimed at speeding up whole-repository indexing
rather than supporting IDE features.
