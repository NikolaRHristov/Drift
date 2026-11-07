---
name: claim-evidence
description: "Use when a report says a thing is done, mounted, rendered or verified."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [macos, linux]
category: Release
metadata:
  hermes:
    tags: [status, evidence, completion, verification, reporting]
    related_skills: [version-parity, round-trip]
---

# Claim Evidence

A status is a claim about the world. A claim is only as good as the artifact that
proves it, and the common failure is not a lie - it is a word that means less than
the reader thinks.

## The invariant

**Every status claim names the artifact that proves it.**

The artifact is a command and its output, a build log, a rendered page, a
fingerprint. A claim with no artifact is a belief, and it belongs in a sentence
that says so.

## The failure it prevents

A long design session produced six layout shells, nine modules, nineteen
components and 180 registered rows, and reported the work complete. It was not:
the build had not run since the newest layers landed, one identity lookup could
never resolve, three reader groups were absent from the dispatcher, and a
comparison asserted equality it had never established.

Nothing in that report was false. Each item had been *written*. The report used a
word - complete - that the reader took to mean *verified*, and the gap between the
two was the whole defect.

The same failure has a one-line form. "Mounted" means imported; "built" means
written; "tested" means the command exited zero on a tree that no longer exists.
Each word is true of an earlier milestone than the one it implies.

## The probe

Take the claim, and ask what command would fail if the claim were false. If there
is no such command, the claim is not checkable and must be restated.

For a status table, require a column per claim:

```text
claim        | artifact                                  | state
written      | the file exists at <path>                 | yes
imported     | the importer names it                     | yes
selected     | the registry resolves it                  | 3 of 5 groups
rendered     | the route's build output contains it      | not checked
verified     | the production build ran after the edit   | not checked
```

A milestone marked `not checked` is the honest answer and the useful one. A
milestone left off the table is read as done.

## The repair

Report the milestone actually reached, and name the artifact for it. Where the
artifact does not exist yet, say that the state is unverified - in the same
breath as the claim, not in a later paragraph.

Skipping a build during a design phase is legitimate. A design phase that ends
without saying the integration state is unverified reads as a finished product
and is not one.

## Pitfalls

- **A file count is not a completion metric.** Nineteen components is a count of
  files. It says nothing about whether a page imports any of them.
- **A green early stage does not imply a later one.** A fetch proves nothing about
  a conversion; a conversion proves nothing about preservation; preservation
  proves nothing about a quality gate. Keep them as separate dimensions, because a
  successful step in one is routinely read as success in all.
- **A dispatcher that silently skips an unresolved item shows "not built" only
  when nothing resolves.** A group missing two of five readers looks healthy.
  Audit expected, resolved and rendered separately, and name partial groups.
- **A comparison can assert equality it never established.** `if a === b` that
  runs on two values that were never read is a green check with no comparison
  behind it. Read the code that produces the values, not the branch that tests
  them.
- **Identical failures across stages are evidence of one real block**, not of
  several transient ones. Four sources failing both a Markdown pass and an HTML
  pass are blocked, and reporting them as retries hides it.
- **A summary of a summary loses the qualifier.** The word "substantially" does
  not survive being quoted, and the reader who receives the second summary has no
  way to recover it.

## Claim-to-test

| Claim | Probe | Pass condition |
| --- | --- | --- |
| Each claim has an artifact | the status table above | no empty artifact column |
| The build ran after the last edit | compare the build output's mtime with the newest source's | output is newer |
| A registry resolves what it should | the dispatcher's expected/resolved counts | equal, or the difference is named |
| A comparison compares | read the function that produces both sides | both sides are values, not constants |
