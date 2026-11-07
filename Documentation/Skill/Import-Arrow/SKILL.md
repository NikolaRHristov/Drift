---
name: import-arrow
description: "Use when one layer of a workspace must not depend on another."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [macos, linux]
category: Tree
metadata:
  hermes:
    tags: [architecture, imports, boundaries, capability, adapter]
    related_skills: [public-surface]
---

# Import Arrow

A workspace that separates a capability from the adapter that implements it has
exactly one rule holding the separation up: the arrow points one way. The rule is
invisible in a build - an import in the wrong direction compiles.

The relation is about any module graph. A Rust workspace reads it from crate
metadata, a JavaScript one from package manifests, a Python one from import
statements; the probe below uses the Rust form because that graph is machine-
readable, and the others need the same arrow checked by a different reader.

## The invariant

**A capability imports no adapter; the facade is named only from outside the
tree.**

## The failure it prevents

The moment a capability imports an adapter, the capability can no longer be
constructed without the provider. Every consumer of the capability now needs the
adapter's dependency graph, and a test of the capability needs a real provider
rather than a stand-in. Nothing fails at the moment the import is added - the
build is green and the binary is larger - so the property is lost silently and
recovered only by a refactor.

The second failure is a cycle. Two crates that each import the other build fine
in a single crate graph and stop building when either is published alone.

## The probe

The dependency graph, read from the manifests rather than from the source, because
a manifest is what cargo resolves:

```sh
cargo metadata --format-version 1 --no-deps |
  jq -r '.packages[] | .name as $p | .dependencies[] | "\($p) -> \(.name)"'
```

Then check the arrows against the rule:

```sh
cargo metadata --format-version 1 --no-deps |
  jq -r '.packages[] | .name as $p | .dependencies[].name | "\($p) \(.)"' |
  awk '$1 ~ /capability/ && $2 ~ /adapter/ { print "arrow reversed:", $1, "->", $2 }'
```

An import in the wrong direction inside one crate is invisible to metadata, so
the source scan is the other half:

```sh
grep -rn 'use .*adapter' --include='*.rs' <capability paths>
```

## The repair

Invert the dependency: declare the port in the capability, and have the adapter
implement it. The capability then names a trait it owns, and the composition root
- which already constructs both - passes the implementation in.

That is the whole reason for a port: without one, the only way to depend on the
implementation is to import it.

## Pitfalls

- **A re-export shadows a crate of the same name.** After `pub use Adapter::Adapter;`
  the next `use Adapter::Serves;` resolves to the trait, not the crate, and the
  compiler answers "`Adapter` is a struct, not a module". Prefix the extern crate:
  `use ::Adapter::Serves;`. Single-word crate names make this the normal case.
- **A dev-dependency is an import arrow.** `[dev-dependencies]` in a capability
  that names an adapter still couples the two for anyone running the tests, which
  is the property the port exists to keep. Check dev-dependencies as well as
  dependencies.
- **A build script's dependency is an arrow too.** `[build-dependencies]` is
  resolved at build time in the same graph.
- **The facade rule is about naming, not about importing.** A consumer naming the
  facade is correct; a crate inside the tree naming it is the arrow reversed, and
  a source grep for the facade's name inside the tree is the only probe for it.
- **A path dependency with no version passes locally and fails packaging.**
  `cargo package` refuses it; the arrow is right and the manifest is wrong.

## Claim-to-test

| Claim | Probe | Pass condition |
| --- | --- | --- |
| No capability depends on an adapter | the `cargo metadata` + `awk` probe | no `arrow reversed` lines |
| No source import crosses the arrow | the `grep` over capability paths | no hits outside a comment |
| The tree is acyclic | `cargo metadata --no-deps` | the binary builds |
| Dev-dependencies obey the rule | `cargo metadata` including dev | no capability → adapter edges |
