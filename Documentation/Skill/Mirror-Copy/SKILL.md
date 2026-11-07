---
name: mirror-copy
description: "Use when one file is written to two destinations that must not disagree."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [macos, linux]
category: Derive
metadata:
  hermes:
    tags: [generated, mirror, copy, redirects, single-source]
    related_skills: [generated-artifact]
---

# Mirror Copy

One render, several destinations. A static host reads `_redirects` from the
public directory; a build directory that is wiped between runs needs its own
copy. Both are written from the same source, so neither is ever edited by hand.

## The invariant

**Every copy is byte-identical to the first.**

The order is the contract. The first path is the reference; the rest are copies.
That is what makes the repair mechanical - there is no judgement about which copy
is right, because the contract already said.

## The failure it prevents

A hand-edited copy survives until the next regeneration and then vanishes, so the
edit that looked like a fix was never in the file the build reads. The reverse is
worse: a copy edited in one place and not the other means the same URL redirects
two ways depending on whether the host serves from the source tree or the build
output, and the difference appears only in production.

## The probe

Compare digests, not diffs - a digest answers the question in one line and cannot
be read as "almost the same".

```sh
shasum -a 256 Public/_redirects Target/_redirects
```

Equal digests are agreement. Different digests are drift, and the first path in
the contract is the one that wins.

A copy that is missing entirely is drift too, and a digest loop reports it
differently from a mismatch:

```sh
for f in Public/_redirects Target/_redirects; do
  [ -f "$f" ] || echo "missing: $f"
done
```

## The repair

Regenerate rather than copy, when a generator exists. Copying propagates whatever
the reference currently says, which is right only if the reference is current.
Regenerating proves both copies and the source at once.

Copying is correct when there is no generator and the first file is authored.

## Pitfalls

- **A generator that always writes defeats a diff-based check.** If the producer
  rewrites the file on every run, comparing timestamps or `git status` after a run
  reports a change every time. Compare content, and require the producer's output
  to be byte-identical for identical input.
- **Sorting by locale makes output unstable.** `localeCompare` orders punctuation
  by locale; sort by code unit instead, or the file differs between two machines
  that agree about everything.
- **Column widths computed from a fixed number make output unstable.** Compute
  them from the widest value, so adding a longer rule does not reflow every line.
- **A generated file copied into a build directory is not tracked.** A missing
  build copy is not drift when the build has not run. State which copies are
  expected at rest, and check only those.
- **A header naming an absolute path leaks a machine into a published file.**
  Name the generator and the source by repository-relative path only.

## Claim-to-test

| Claim | Probe | Pass condition |
| --- | --- | --- |
| The copies agree | `shasum -a 256 <paths>` | identical digests |
| Regeneration is idempotent | run the generator twice, digest after each | same digest both times |
| The copy is not hand-edited | `grep -n 'Generated file' <copy>` | the header is present in every copy |
| No machine path in the copy | `grep -n "$HOME" <copy>` | no hits |
