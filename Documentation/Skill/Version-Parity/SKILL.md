---
name: version-parity
description: "Use when a release states one version in several manifests or pins."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [macos, linux]
category: Release
metadata:
  hermes:
    tags: [release, version, manifest, parity, pin]
    related_skills: [public-surface]
---

# Version Parity

A release names one version in five files - two manifests, a package file, a
plugin descriptor, and a pointer that a distribution reads. Four of them are
copied by hand.

## The invariant

**Every declaration of one version states the same value.**

A second invariant rides beside it, and it is a different relation: **a pointer
that names a release names one whose assets exist.**

## The failure it prevents

A parity failure is a release that installs one version and reports another. The
plugin loads the binary it pinned, the binary reports its own version, and a bug
report names the wrong build - so every later diagnosis starts from a false fact.

A pointer failure is worse because it is asymmetric. The version is bumped before
the assets are published, so the pointer names a release that does not exist yet,
and every install fails to download while the repository looks correct. The
ordering is the invariant: publish the assets, then move the pointer.

## The probe

Read every declaration through the one place in each file that states it, then
compare:

```sh
grep -n '^version' crates/*/Cargo.toml
jq -r '.version' package.json
head -1 plugins/<name>/BINARY_VERSION
```

A loop that prints `file: value` and sorts by value makes a disagreement one line
long:

```sh
{ grep -H '^version' crates/*/Cargo.toml | sed -E 's/version *= *"([^"]+)"/\1/'
  echo "package.json: $(jq -r '.version' package.json)"
  echo "BINARY_VERSION: $(head -1 plugins/<name>/BINARY_VERSION)"
} | awk -F': ' '{ print $2 }' | sort -u | wc -l
```

`1` is agreement. Anything else is drift, and the loop above names which file
differs.

For the pointer, ask the distribution rather than the file:

```sh
gh release view <tag> --repo <owner>/<repo> --json assets -q '.assets[].name'
```

An empty list, or a 404, means the pointer is ahead of the release.

## The repair

There is no mechanical repair, deliberately. A disagreement does not say which
value is right: raising the manifests to the artifact's version and rewinding the
artifact to the manifests' are both repairs, and they mean different releases. The
probe names every value; the decision is a release decision.

The pointer has an order, not a repair:

1. Build and publish the assets for the new version.
2. Confirm they exist and their digests match what the release recorded.
3. Move the pointer last, in its own commit.

A pointer bumped first cannot be un-bumped without a second commit that will be
read as a rewind.

## Pitfalls

- **Two independent version lines are not one parity group.** A binary version and
  a plugin version move together but are not equal; a guard that compares them
  reports drift on every correct release. Group by what must be equal, not by what
  must move together.
- **A version embedded in a badge is a declaration.** A README badge that states
  the version is read by people and never by a tool, which is exactly why it is
  the last one to be updated and the first to be wrong.
- **A generated digest file may restate the version.** A `SHA256SUMS` header
  naming the version is a declaration; regenerate it rather than editing it.
- **A lockfile is not a declaration.** It records what was resolved, it is
  regenerated, and it is not the version the product states.
- **A prerelease suffix sorts differently from what a human expects.** `1.7.0-rc.1`
  is lower than `1.7.0`; a comparison that sorts strings will order them wrongly
  and a comparison that ignores the suffix will call them equal. State which one
  the guard means.

## Claim-to-test

| Claim | Probe | Pass condition |
| --- | --- | --- |
| Every declaration agrees | the `sort -u | wc -l` loop | `1` |
| The pointer names a real release | `gh release view <tag> --json assets` | the asset list is non-empty |
| The assets match the recorded digests | `shasum -a 256 -c SHA256SUMS.txt` | every line `OK` |
| The pointer moved last | `git log --oneline -- <pointer path>` | its commit is newer than the tag |
