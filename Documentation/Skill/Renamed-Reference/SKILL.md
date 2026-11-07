---
name: renamed-reference
description: "Use after a rename or move, when prose and comments still name the old thing."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [macos, linux]
category: Tree
metadata:
  hermes:
    tags: [rename, move, references, stale-name, residue]
    related_skills: [duplicate-declaration, shadowed-definition]
---

# Renamed Reference

A rename touches the definition and every reference to it. The compiler checks
the references it can see; it sees none of the ones in prose, comments, paths or
shell strings.

## The invariant

**No tracked file names a thing by a name it no longer has.**

## The failure it prevents

A module is renamed, the code compiles, and eleven documents still describe the
old path. A reader follows the documentation, the file is not there, and the
repair they attempt is based on a tree that no longer exists.

The residue has a shape. It is never one place: a comment in the file that moved,
a usage line in a README, a cross-reference in a sibling document, a path in a
script, a heading in a plan. Each was correct when written and none of them
breaks a build.

A second form is worse because it looks alive: a stale name that still resolves.
A deleted check script named in a comment, a command that used to exist, a flag
that was removed - the reference is to something that once worked, so it reads as
current.

## The probe

Search for the old token, not for the new one, and search every surface:

```sh
grep -rn '<old-name>' --include='*.md' --include='*.rs' --include='*.ts' \
  --include='*.mjs' --include='*.sh' --include='*.toml' --include='*.json' .
```

Then the two searches that catch what the first misses:

```sh
grep -rIn '<old-path-segment>' .          # a path quoted without its file name
git ls-files | grep -i '<old-name>'       # a file or directory that was never moved
```

The second is the one people skip. A rename that updated every reference and left
the file in place has renamed nothing.

## The repair

Rewrite each hit to the new name, and delete the reference where the thing is
gone rather than pointing it at a replacement that is not equivalent. A comment
that says "see `<deleted>`" is worse than no comment.

Where a document must name the old name - a changelog, a migration note, a
deprecation - say so in the line, so the next sweep does not flag it.

## Pitfalls

- **A word-boundary search misses the compound.** `\bUrl\b` does not match
  `UrlPath` or `myUrl`. Search the substring, then decide case by case.
- **A substring replacement corrupts compound words.** Renaming `Id` → `ID` by
  substring turns `HoldsIdentity` into `HoldsIDentity`, which compiles and reads
  as a typo everywhere. After a bulk pass, search for the damage directly:
  `[A-Za-z]ID[a-z]`.
- **A rename that reaches a serialised key changes the wire format.** A key
  renamed in a JSON schema breaks every reader still sending the old one. Check
  whether the name is part of a contract before touching it; if it is, the key
  stays and only the local binding is renamed.
- **A dependency's spelling is not yours to change.** A third-party API keeps its
  name even when every local identifier changes. Say which boundary was left
  alone, or the next reader reads the inconsistency as an oversight.
- **The sweep is not done until the token inventory is re-run.** A rewrite that
  matched nothing exits zero and reports success; re-count the old token and
  compare with the count before the pass.
- **A rename recorded only in the diff is not a rule.** The next reader cannot
  apply it. Write the naming rule down where the tree keeps its conventions, and
  run the sweep against that.

## Claim-to-test

| Claim | Probe | Pass condition |
| --- | --- | --- |
| No old name survives | `grep -rn '<old-name>'` over tracked files | only the documents that name it on purpose |
| No file kept the old name | `git ls-files | grep -i '<old-name>'` | no hits |
| The sweep changed something | the token count before and after | the count dropped to the intended number |
| No compound was corrupted | `grep -rnE '[A-Za-z]ID[a-z]'` after an acronym pass | no hits |
| The rule is written down | the repository's style document | it names the convention the pass applied |
