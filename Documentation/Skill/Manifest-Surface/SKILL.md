---
name: manifest-surface
description: "Use when a manifest declares tools, hooks or commands a document also lists."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [macos, linux]
category: Derive
metadata:
  hermes:
    tags: [manifest, registry, tools, hooks, surface, set-equality]
    related_skills: [duplicate-declaration, version-parity]
---

# Manifest Surface

A manifest declares what a component provides: its tools, its hooks, its
commands. A document lists the same surface for a reader. Both are hand-maintained
and neither is generated from the other.

Worked instance: a content-integrity guard compares a plugin manifest's declared
hook and tool lists against a documentation table's numbered registry - the
manifest is the declaration and the table is the copy.

## The invariant

**The documented surface equals the declared surface, as a set.**

A count is not the invariant. A count is a weaker claim that passes when one item
is added and another removed in the same change.

## The failure it prevents

A tool is added to the manifest and not to the registry table. The tool works and
is invisible: nobody reading the documentation knows to call it, and nobody
reviewing the manifest notices the table did not change. The inverse is the
expensive direction - a documented tool that was removed still has a reader
trying to call it, and the failure reads as a bug in the caller.

The count form of the check is the trap. `provides 13 tools` passes when the
manifest has fourteen and the doc has thirteen, and it passes again when both
have thirteen but they are not the same thirteen.

## The probe

Extract both sides, sort both sides, compare the sets:

```sh
<extract-declared>   | sort > /tmp/declared
<extract-documented> | sort > /tmp/documented
diff /tmp/declared /tmp/documented
```

An empty diff is agreement. A line on the left is a declared item nobody can read
about; a line on the right is a documented item that no longer exists.

Where the manifest is not machine-readable, extract with the pattern the file
already uses, and state the pattern - a regex that silently matches nothing
produces two empty sets and a passing diff, which is the worst outcome.

```sh
grep -c '^  - ' <manifest>   # how many the extractor should have found
```

That second number is the guard on the guard: if the extractor returns zero, the
comparison proved nothing.

## The repair

Add the missing row, or remove the stale one. Where the surface is large enough
that hand-maintenance is the cause, generate the table from the manifest and mark
the file as generated - a table that cannot disagree is better than one that is
compared.

## Pitfalls

- **Order is presentation; the comparison is a set.** A numbered registry table
  and a manifest list will differ in order forever. Sort both sides, and say in
  the guard that the order is not part of the claim.
- **A count check passes on a swap.** `13 == 13` is true for two different
  thirteens. Compare the members.
- **An extractor that matches nothing yields two empty sets and a green diff.**
  Assert a minimum size on each side before comparing.
- **A documented surface may legitimately be larger.** A document may describe
  planned or deprecated items. If so, mark those rows so the guard can exclude
  them rather than being relaxed to a subset check that hides removals.
- **A manifest key renamed in the same change breaks the extractor silently.**
  Re-run the extractor after a schema change and check its count, not just the
  diff.
- **The doc may be generated and the manifest hand-written.** Then the drift runs
  the other way: the generator reads a stale copy. Check which side is derived
  before choosing which to edit.

## Claim-to-test

| Claim | Probe | Pass condition |
| --- | --- | --- |
| The sets agree | the sorted `diff` above | empty |
| Both extractors found something | their line counts | both non-zero and plausible |
| No item was swapped for another | the `diff`, not the counts | empty |
| The table is generated, if it is | the file's header and its generator | the generator exists and runs |
| Removals are visible | remove one item from the manifest and re-run | the guard fails |
