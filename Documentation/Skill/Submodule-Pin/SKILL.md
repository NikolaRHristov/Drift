---
name: submodule-pin
description: "Use when a parent records a submodule commit, or a clone checks out the wrong tree."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [macos, linux]
category: Git
metadata:
  hermes:
    tags: [git, submodule, gitlink, pin, phantom]
    related_skills: [branch-invariant, remote-identity]
---

# Submodule Pin

A parent repository records, for each submodule, one commit ID. That ID is the
reference. Two things must agree with it: the submodule's remote must serve it,
and the submodule's checkout must sit on it.

## The invariant

**A recorded submodule commit is a commit the remote serves, and the checkout is
on it.**

## The failure it prevents

The two halves fail differently, and neither is visible in a diff.

**A phantom pin** is a recorded commit the remote does not serve. Nothing is
wrong locally - the object is in the local store, the build passes - and the
failure appears on someone else's clone as `upload-pack: not our ref`. It happens
when a submodule commit is made on a detached HEAD, or on a branch that was later
rewritten or deleted, and then recorded by the parent.

**A stale pin** is a recorded commit the submodule has moved past. `git submodule
status` prefixes the entry with `+`. A fresh clone checks out the recorded tree,
so a file that exists only in the newer commit is simply absent, and the build
failure that follows names the absent file rather than the pin.

## The probe

Three questions, in increasing cost. Ask only the one you need.

**Local - is each checkout on its pin?** No network.

```sh
git submodule status --recursive
```

A line beginning with `+` is a stale pin: the checkout is ahead of or diverged
from the record. A line beginning with `-` means the submodule is not
initialised, which is not drift. A leading space is agreement.

**Reachable - does the remote serve the recorded commit?** One fetch per pin.

```sh
git ls-files -s | awk '$1 == "160000" { print $2, $4 }'
```

Then, for each `<sha> <path>`, read the URL from `.gitmodules` and fetch the exact
object:

```sh
git fetch --quiet <url> <sha>
```

Exit `0` proves some advertised ref reaches the commit. A non-zero exit with
`not our ref` is a phantom pin.

**Current - is the pin the remote's default-branch tip?**

```sh
git ls-remote --symref <url> HEAD
```

The first field of the line whose second field is `HEAD` is the tip. Compare it
with the pin. This is the question a release repository asks; a library that pins
a dependency deliberately asks the first two and not this one.

## The repair

A phantom pin is repaired by making the commit real - push the branch that
contains it, then re-record the pin - or by re-recording the pin to a commit the
remote already serves. Which one is right is a decision about what the submodule
was supposed to contain, so there is no command here.

A stale pin is repaired by recording the checkout:

```sh
git add <path>
git commit -m "chore: bump submodule gitlinks: <path>@<sha>"
```

That commit is mechanical, so it belongs in a hook rather than in a habit.
`Documentation/Hook/Lib/bump-submodule-gitlinks.sh` is the one that runs in a
parent repository; `Documentation/Hook/Index.md` names it and the hooks that call
it.

## Pitfalls

- **`git submodule status` reports the record, not the remote.** It cannot see a
  phantom pin, because the object exists locally. Only a fetch answers that
  question.
- **A fetch of the exact SHA succeeds for any commit the remote serves, on any
  ref.** That is the point - it answers reachability, not intent. Do not read a
  successful fetch as "this pin is correct", only as "this pin is real".
- **`git merge-base --is-ancestor <pin> origin/<branch>` is an optimisation, not
  a substitute.** It answers only after the parent's default branch is fetched,
  and it answers about one branch. Use it to skip a network call, never to
  conclude a pin is unreachable.
- **A submodule is advanced by committing inside the parent's checkout, not in
  the repository it was cloned from.** `Parent/Sub` and the source `Sub` are two
  repositories with two `HEAD`s; a commit in the source moves neither the
  parent's index nor the checkout, so `git submodule status` correctly reports
  in-sync while the source has moved on. A probe that advances the source and
  then expects `+` is measuring the wrong repository, and it will pass or fail
  for a reason unrelated to the guard.
- **`ignore = all` in `.gitmodules` hides a dirty submodule, not a moved one.** A
  pointer update still appears; a modified worktree does not. That is why the
  bump hook compares with `git diff HEAD -- <path>` rather than reading status.
- **A submodule that is itself a parent must not run the bump.** The hook checks
  `git rev-parse --show-superproject-working-tree` and exits when it is non-empty;
  without that, a nested bump commits inside `vendor/` and the outer parent never
  sees it.

## Claim-to-test

| Claim | Probe | Pass condition |
| --- | --- | --- |
| No checkout has moved past its pin | `git submodule status --recursive` | no line begins with `+` |
| Every pin is served by its remote | `git fetch --quiet <url> <sha>` per pin | exit 0 |
| Every pin is current | `git ls-remote --symref <url> HEAD` | tip equals pin |
| The bump is automatic | `git config --get core.hooksPath` | names the directory holding the hooks |
