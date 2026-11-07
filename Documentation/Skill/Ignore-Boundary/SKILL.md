---
name: ignore-boundary
description: "Use when an ignore file may be hiding a path something else needs."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [macos, linux]
category: Tree
metadata:
  hermes:
    tags: [gitignore, prettierignore, negation, glob, silent-failure]
    related_skills: [workspace-membership, generated-artifact]
---

# Ignore Boundary

An ignore file states what a tool must not own. It is read as a boundary, and it
is written as a glob, and the two are not the same thing.

## The invariant

**An ignore rule excludes only what nothing needs; every path a build, hook or
script writes is outside the boundary.**

## The failure it prevents

The failure is silent, which is why it survives. A directory pattern in
`.gitignore` excludes everything inside it, and `git add` of an explicit path
inside it fails - the file is ignored regardless of how precisely it was named.
A script that runs `git add` and `git commit` then reports success while staging
nothing, because it does not check.

The second form is a pattern that matches more than intended. A `*.json` line
excludes that class at every depth, so a schema, a fixture and a manifest are all
invisible at once, and `git add -A` exits zero with a clean `status` while the
files are simply untracked. The check that would have caught it - `git ls-files`
for the paths meant to be committed - is the one nobody runs, because the commit
message already said what was meant.

The third form is a formatter's ignore file used as a repair. Adding an entry to
`.prettierignore` so a check passes converts a visible disagreement into an
invisible one, and at a glance an entry in a formatter's skip list is
indistinguishable from a version-control ignore.

## The probe

Ask git, not the ignore file, and ask per path:

```sh
git check-ignore -v <path>
```

No output means the path is not ignored. Output names the file and line that
ignored it, which is the diagnosis: a rule written for something else is matching
this.

For a whole set of paths something writes, the loop is the guard:

```sh
for p in <paths the build writes>; do
  git check-ignore -q "$p" && echo "ignored but needed: $p"
done
```

And for the intent check, compare what is tracked with what should be:

```sh
git ls-files <directory> | wc -l
```

A count lower than the number of files on disk is either correct - build output -
or the drift.

## The repair

Narrow the rule to the thing it was written for, and re-include deliberately:

```text
<directory>/*
!<directory>/<path something needs>
```

A negation cannot resurrect a file whose parent directory is excluded, so the
parent must be un-ignored first and its contents ignored one level down. That
ordering is the whole difficulty of the file, and it is why a negation added at
the end of a `.gitignore` frequently does nothing.

Where the path is build output that a step needs downstream, it stays ignored and
the step reads it from disk rather than from git. Ignoring is not the defect;
expecting git to carry an ignored path is.

## Pitfalls

- **`!path` does not work inside an ignored directory.** Git does not descend into
  an excluded directory, so no rule inside it is evaluated. Un-ignore the
  directory, then ignore its contents.
- **An unanchored glob matches at every depth.** `Target/` matches a directory of
  that name anywhere in the tree, and can hide a real source directory that
  happens to share the name. Anchor with a leading slash when the rule means the
  repository root.
- **`git add -A` exiting zero is not evidence anything was added.** Check
  `git ls-files` for the paths, or `git status --porcelain` for their absence.
- **A formatter's ignore file is not a place to park an inconvenient file.** It
  states what the formatter must not own. If a file must keep bytes the formatter
  would change, leave the warning standing or ask which of the two is wanted.
- **`.gitignore` is not a publication boundary.** A file added with `git add -f`,
  or one no pattern matched, is tracked and published regardless. Ask git.
- **A directory pattern and a file pattern are different questions.** `build/`
  excludes a directory and everything under it; `build` excludes a file or a
  directory at any depth. State which one the rule means.

## Claim-to-test

| Claim | Probe | Pass condition |
| --- | --- | --- |
| Every needed path is tracked | `git check-ignore -q <path>` per path | exit non-zero |
| The rule matches only its target | `git check-ignore -v <path>` | the named file and line are the intended rule |
| A negation works | `git check-ignore -v <path>` after adding it | no output |
| The ignore file is not a repair | `git log -p -- .prettierignore` | no entry added to silence a check |
| Nothing needed is missing | `git ls-files <dir>` against the files on disk | the difference is build output only |
