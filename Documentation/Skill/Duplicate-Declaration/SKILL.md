---
name: duplicate-declaration
description: "Use when one fact is written down in two places that must stay equal."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [macos, linux]
category: Derive
metadata:
  hermes:
    tags: [duplication, single-source, vocabulary, contracts]
    related_skills: [mirror-copy, import-arrow]
---

# Duplicate Declaration

A fact stated once is a fact. A fact stated twice is two facts that happen to
agree, and they will stop agreeing at the first edit nobody mirrored.

## The invariant

**One concept is declared once. Every other place that needs it links to that
declaration or is generated from it.**

## The failure it prevents

Two component libraries described the same thirty contracts under two trees and
two slot vocabularies. Both were built; neither was chosen; every later edit
depended on which one a route happened to import. The cost was not the
duplicated code - it was that no question about the system had one answer.

The smaller version is more common and easier to miss. A README states the
commands; the CLI's own help states the commands. The README is updated by hand
and the help is generated, so the README is right until the week it is wrong, and
a reader who follows it gets an error the author never saw.

A third form: a task-to-skill table in two files. The one nobody reads is always
the stale one, and nobody can tell which is which.

## The probe

Name the fact, then count the places it is written:

```sh
grep -rn '<the fact>' --include='*.md' --include='*.json' --include='*.toml' .
```

Two hits are two declarations unless one is a link. Read both; a link reads as a
path or a URL, a declaration reads as the value.

For a vocabulary, compare the key sets rather than the text:

```sh
jq -r 'keys[]' a.json | sort > /tmp/a.keys
jq -r 'keys[]' b.json | sort > /tmp/b.keys
diff /tmp/a.keys /tmp/b.keys
```

An empty diff on two files that describe the same thing is the drift, not the
absence of it: it means the copy is being maintained, and the copy is the one
that will be forgotten.

## The repair

Delete one. The honest options, in order of preference:

1. **Generate** the second from the first, so a disagreement is impossible
   rather than merely unlikely.
2. **Link** the second to the first - a path, an include, a symlink - so there is
   one text.
3. **Delete** the second, if nothing reads it. A document nobody reads is a
   document that will be wrong.

What is not a repair: adding a note that says "keep this in sync with X". That
note is a third declaration of the fact, and it drifts too.

## Pitfalls

- **A generated copy is not a duplicate, but a hand-edited generated copy is.**
  If the generator runs, the copy is derived and safe. If someone edits it in
  place, the next run silently discards the edit - check whether the file carries
  a "generated" header and whether a generator still writes it.
- **A doc table and a code table drift in opposite directions.** The code table
  is authoritative and unreadable; the doc table is readable and stale. Compare
  the rows, not the formatting.
- **Two formats of one schema is a duplicate even when the tooling needs both.**
  A JSON schema and a TypeScript type that must agree are one declaration and one
  derivation; if both are hand-written, generate the weaker one.
- **A "canonical" label on both copies is the defect.** Two files that each claim
  to be the source of truth are two sources; the label is evidence the choice was
  deferred.
- **A second list is not made safe by being shorter.** A summary table drifts
  faster than a full one because it is edited by people who are in a hurry.

## Claim-to-test

| Claim | Probe | Pass condition |
| --- | --- | --- |
| The fact is declared once | the `grep` above | one declaration; every other hit is a link |
| A derived copy is derived | its header, and the generator that writes it | the generator exists and runs |
| Two vocabularies agree because one is generated | `diff` of the key sets after regeneration | empty diff, and the generator is the writer |
| Nothing claims to be canonical twice | `grep -rin 'source of truth\|canonical'` | one hit per fact |
