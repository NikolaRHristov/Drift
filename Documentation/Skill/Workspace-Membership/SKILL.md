---
name: workspace-membership
description: "Use when a package directory and the workspace's member list may disagree."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [macos, linux]
category: Tree
metadata:
  hermes:
    tags: [workspace, monorepo, pnpm, cargo, membership]
    related_skills: [ignore-boundary, import-arrow]
---

# Workspace Membership

A workspace names its members. The directory tree holds packages. Nothing keeps
the two lists equal.

## The invariant

**Every package directory is a member, and every member exists.**

Two directions, and both fail silently. A directory that is not a member is never
built, never type-checked and never published - it is a package in name only. A
member that names a directory that no longer exists either fails the whole install
or is silently skipped, depending on the tool.

## The failure it prevents

A package is scaffolded, its tests pass when run by hand, and the workspace file
is not updated. The build is green because the build never sees it. The failure
appears months later, when someone imports the package and the resolution fails,
and the diagnosis starts from "the package does not exist" - which is true of the
workspace and false of the disk.

The reverse direction is noisier but just as confusing: a member entry for a
renamed directory makes the install fail with a path error that names neither the
rename nor the file that needs editing.

The third form is a build approval. A native dependency that needs a build step
must be allowed explicitly; without the allowance the install exits non-zero, and
because every script in a workspace runs through an install precheck, one
unapproved dependency takes down every command at once.

## The probe

Compare the two lists, in both directions. Filter to directories that actually
declare a package: listing every directory reports the site's own `Source/`,
`Public/` and `Documentation/` as missing members, and that noise is how a real
omission gets ignored.

```sh
find . -name package.json -not -path '*/node_modules/*' -maxdepth 3 |
  sed 's|/package.json||; s|^\./||' | sort > /tmp/packages
pnpm ls -r --depth -1 --json 2> /dev/null | jq -r '.[].path' |
  sed "s|$PWD/||; s|^\.$|.|" | sort > /tmp/members
comm -3 /tmp/packages /tmp/members
```

A line on the left is a package the workspace does not build. A line on the
right is a member whose directory is gone.

For Cargo, the resolved member list is the manifest's own answer:

```sh
cargo metadata --no-deps --format-version 1 | jq -r '.packages[].name'
cargo metadata --no-deps --format-version 1 > /dev/null
```

The second command is the reverse direction: a member that names a directory that
does not exist makes it exit non-zero, and the error names the member.

For a package manager that requires build approval, the allowance is part of the
contract:

```sh
grep -n 'allowBuilds' pnpm-workspace.yaml
```

## The repair

Add the missing member, or remove the stale one. Prefer an explicit member list
to a glob: a glob is a second statement of what ships, and it changes when a
directory is added - which is exactly the moment nobody is looking at the
manifest.

When a directory is renamed, the member entry is one of the places that must
change, and it is the one no compiler checks.

## Pitfalls

- **A glob hides both directions.** `Crate/*` stops at a group directory and
  `Crate/*/*` reaches one level further; a new nesting depth silently drops out of
  both. An explicit list is longer and is the one that tells the truth.
- **An exclusion list grows and is never pruned.** A path excluded to unblock a
  build stays excluded after the reason is gone, and the package it names is
  never built again.
- **A build approval is part of membership.** A dependency that needs a native
  build and has no allowance makes the install fail, and an install failure makes
  every script fail through the precheck - which reads as "the whole workspace is
  broken" rather than "one dependency is unapproved".
- **A lockfile is not a member list.** It records what was resolved, including
  members that were later removed. Compare against the manifest, not the lock.
- **A workspace-level ignore can hide a member's own files.** An ignore rule
  anchored at the root does not apply inside a member, and one that is not
  anchored can apply everywhere. Check `git check-ignore -v` inside the member.

## Claim-to-test

| Claim | Probe | Pass condition |
| --- | --- | --- |
| Every directory is a member | `comm -3` of directories and members | no lines on the left |
| Every member exists | `cargo metadata --no-deps` or the install | exit 0 |
| The build sees the package | the build's output lists it | the package name appears |
| The allowance is declared | `grep allowBuilds` in the workspace file | the dependency is named |
| The exclusion list is current | each excluded path, checked by hand | each has a reason that is still true |
