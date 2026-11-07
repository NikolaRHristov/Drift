---
name: public-surface
description: "Use before publishing a tree: machine paths, real identifiers, process notes."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [macos, linux]
category: Tree
metadata:
  hermes:
    tags: [public, leak, scrub, identifiers, paths]
    related_skills: [version-parity]
---

# Public Surface

A repository that is public publishes every tracked byte, for as long as it
exists. Three classes of content belong to the machine or the process and must
never be in it.

## The invariant

**A public tree contains no machine path, no real identifier and no internal
process artifact.**

Three separate relations, one rule: each names something that is true locally and
must not be true publicly.

## The failure it prevents

**A machine path** - `/Users/<name>/…`, `/Volumes/<volume>/…`, a home directory in
a header - tells a reader where the author's disk is laid out, and breaks for
every other reader. It also makes a document that looked portable into one that
works on exactly one machine.

**A real identifier** - a list id, a handle, a post id, an account id - is
content that was supposed to stay in a gitignored local file. A placeholder that
reads as a template is fine; a working value copied into a tracked file is a
disclosure, and a link built from it is a live link.

**An internal process artifact** - a handoff note, a feedback file, a task queue,
a binding-contract reference - describes how the work was organised rather than
what the repository is. A reader who finds it learns the shape of a private
process and nothing about the software.

## The probe

Tracked files only. An untracked file is not published, and a scan that includes
one reports a defect that does not exist.

```sh
git ls-files -z | xargs -0 grep -In -E '/Users/|/Volumes/|\$HOME/' 
```

```sh
git ls-files -z | xargs -0 grep -In -iE 'handoff|feedback-note|task-queue|binding contract'
```

Identifiers cannot be found by pattern, because the point of a real value is that
it looks like any other. Scan for the shapes instead - a long hex string, a UUID,
a numeric id beside a word like `list` or `channel` - and then read the hits:

```sh
git ls-files -z | xargs -0 grep -In -E '[0-9a-f]{32}|[0-9a-f]{8}-[0-9a-f]{4}-'
```

## The repair

Replace with a placeholder that reads as a template - `<owner>`, `<list-id>`,
`AI`/`UI`/`CODE` for a category - and keep the real value in the gitignored local
file the code already reads.

Do not over-correct. A working contact address stays real, and a public link stays
a public link; replacing either with a reserved placeholder like `example.com`
turns a correct document into a dead one. Placeholders are for values that are
private, not for values that are merely specific.

## Pitfalls

- **A scan over the working tree reports untracked scratch.** `git ls-files` is
  the only honest input; a local archive or a gitignored store is not published
  even though it is on disk.
- **`.gitignore` is not a publication boundary.** A file added with `git add -f`,
  or a pattern that never matched, is tracked and published regardless of what the
  ignore file says. Ask git, not the ignore file.
- **A submodule's content is not this repository's content.** `git ls-files`
  names the gitlink, not the files inside it; scan the submodule in its own
  checkout, with its own tracked-file list.
- **A redacted-looking line may be display masking, not the file's bytes.** A
  tool that shows `Bearer ***` may be masking a real token, or the file may
  contain a placeholder. Read the bytes - `git show HEAD:<path> | grep -c` - before
  reporting a defect or a clean scan.
- **A grep for a word boundary misses the compound.** `\bUrl\b` does not match
  `UrlPath`. Search the substring, then decide case by case.

## Claim-to-test

| Claim | Probe | Pass condition |
| --- | --- | --- |
| No machine path | the `git ls-files` grep above | no hits |
| No process artifact | the second grep above | no hits |
| No identifier | the shape scan, read by hand | every hit is a placeholder or a public value |
| The scan covered the tree | `git ls-files | wc -l` | matches the file count you expect |
