---
name: branch-invariant
description: "Use when a commit or checkout may have left a repository on a detached HEAD."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [macos, linux]
category: Git
metadata:
  hermes:
    tags: [git, detached-head, branch, hook, dangling]
    related_skills: [submodule-pin]
---

# Branch Invariant

A repository is supposed to sit on a branch. A checkout of a commit - which a
submodule pin bump does routinely - puts `HEAD` on the commit instead, and from
that moment the repository is not on a branch at all.

## The invariant

**Every repository and every submodule is on a branch, at all times.**

## The failure it prevents

A commit made while `HEAD` is detached lands on no branch. Nothing names it:
`git log` on any branch cannot reach it, `git branch --contains` cannot list it,
and only the reflog remembers, for ninety days by default. When the worktree
moves, the commit is unreachable and the work in it is gone.

The second failure is quieter. A detached checkout of a submodule *looks*
correct - the files are the right files - so a `git submodule update` that
detaches is not noticed until the next commit is refused, or until a pin is
recorded pointing at a commit on no branch, which is the phantom pin the
`Submodule-Pin` skill describes.

## The probe

`git symbolic-ref -q HEAD` exits non-zero exactly when `HEAD` is detached.

```sh
git symbolic-ref -q HEAD > /dev/null || echo "detached: $(git rev-parse HEAD)"
```

Over a tree of repositories, one line each:

```sh
find . -name .git -prune -print | while read -r d; do
  git -C "$(dirname "$d")" symbolic-ref -q HEAD > /dev/null || echo "detached: $(dirname "$d")"
done
```

A repository whose `.git` is a file rather than a directory - a worktree, or a
submodule - is found by the same `find`, because `-name .git` matches the file.

## The repair

If the commit is contained in a branch, checking that branch out loses nothing:

```sh
git branch --contains "$(git rev-parse HEAD)" --format='%(refname:short)'
git checkout <branch>
```

If the list is empty the commit is on no branch, and the only repair that keeps
it is to name it first:

```sh
git branch <name> "$(git rev-parse HEAD)"
git checkout <name>
```

Do not reach for a reset or a restore. The commit is the only copy of the work.

## Prevention

The probe is cheap and the failure is unrecoverable, so both directions are
hooks. `Documentation/Hook/pre-commit` refuses a commit while `HEAD` is detached
and names the re-attach command. `Documentation/Hook/post-checkout` re-attaches
automatically when the commit is contained in a branch, and warns when it is not.

`Documentation/Hook/Index.md` names both files. Install them where
`core.hooksPath` points.

## Pitfalls

- **A `post-checkout` that re-attaches unconditionally loses the checkout's
  intent.** The hook must run only when `HEAD` is detached *and* a branch
  contains the commit; otherwise it turns every deliberate `git checkout <sha>`
  into a no-op.
- **The re-attach fires `post-checkout` again.** Without a recursion guard the
  hook loops. `DETACH_REATTACH_ACTIVE=1` in the environment of the nested
  checkout is the guard, and it must be set on the command, not exported for the
  rest of the session.
- **`git branch --contains` lists `(no branch)` for the detached `HEAD` itself.**
  That entry is not a branch; filtering it out is what makes an empty list mean
  "on no branch" rather than "on one".
- **A hook is only a guard where `core.hooksPath` points at it.** A `.githooks`
  directory that no clone configures is documentation. Verify with `git config
  --get core.hooksPath` from the repository root.
- **An extensionless hook with CRLF line endings never runs.** The shebang
  becomes `env: bash\r` and the interpreter is not found; the file still looks
  installed. Pin `eol=lf` for the hook paths in `.gitattributes`.

## Claim-to-test

| Claim | Probe | Pass condition |
| --- | --- | --- |
| No repository is detached | `git symbolic-ref -q HEAD` in each | exit 0 |
| The commit guard is wired | `git config --get core.hooksPath` | names the hook directory |
| The guard refuses | stage a change on a detached `HEAD` and commit | exit non-zero, message names the re-attach |
| The re-attach does not loop | `git checkout <sha>` where a branch contains it | lands on that branch, one line of output |
| The hooks are LF | `file .githooks/pre-commit` | no `CRLF` |
