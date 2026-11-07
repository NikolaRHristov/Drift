---
name: remote-identity
description: "Use when a declared remote or .gitmodules URL may name a moved repository."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [macos, linux]
category: Git
metadata:
  hermes:
    tags: [git, remote, gitmodules, redirect, rename]
    related_skills: [submodule-pin]
---

# Remote Identity

A `.gitmodules` entry and a remote both name a repository by owner and name.
GitHub keeps a redirect after a rename or a transfer, so a stale URL keeps
working - which is exactly why the drift survives.

## The invariant

**Every declared remote URL names the repository's current owner and name.**

## The failure it prevents

A redirect is served by one host and by no other. A tree whose URLs depend on it
clones fine on GitHub and fails on a mirror, a proxy, an offline bundle, or an
archival service. The failure reads as a network problem rather than as a stale
URL, so it is diagnosed in the wrong place.

The second failure is a URL that names an owner that no longer holds the
repository. Once the old name is released, anyone may claim it, and the stale URL
then points at a stranger's repository. A clone of that tree fetches somebody
else's code under the name the tree expected.

## The probe

Every URL under a tree, resolved through redirects:

```sh
grep -rhoE 'url = (https://|ssh://git@)github\.com/[^[:space:]]+' --include=.gitmodules . |
  sed -E 's|^url = ||; s|\.git$||' |
  while read -r url; do
    effective="$(curl -s -L -o /dev/null --max-time 10 -w '%{url_effective}' "$url")"
    [ "${effective%/}" = "${url%/}" ] || echo "redirect: $url -> $effective"
  done
```

A printed pair is a stale URL; the right-hand side is the current identity. A URL
whose request fails entirely is unknown rather than correct - it is neither
confirmed nor condemned by this probe.

Remotes in a checkout, rather than in `.gitmodules`:

```sh
git remote -v
git ls-remote --get-url <name>
```

`git ls-remote --get-url` applies `insteadOf` rewrites, so it answers what git
will actually contact rather than what the config stores.

## The repair

Rewrite the URL in place, preserving every other byte of the file - line endings,
`ignore = all`, `shallow`, `branch`. A rewrite that reformats the file turns one
changed line into a whole-file diff and hides the change under noise.

Then confirm:

```sh
git config -f .gitmodules --get-regexp '\.url$'
```

External upstreams that do not redirect stay untouched. A `.gitmodules` file is
not a list of this organisation's repositories; it is a list of every repository
the tree needs, and most of them belong to someone else.

## Pitfalls

- **A redirect is not an error.** `curl -L` following it to a 200 is the healthy
  case for a stale URL, and the trap: the probe must compare the *effective* URL
  with the declared one, not the status code.
- **`%{url_effective}` is the final URL, not the first hop.** That is what makes
  the comparison meaningful - an intermediate hop is invisible, and only the
  destination matters.
- **Case matters to the probe and not to the host.** GitHub treats `Owner/Repo`
  and `owner/repo` as the same repository, so a case-only difference is not
  drift. Compare case-insensitively, or accept the redirect and move on.
- **`ssh://git@github.com/...` and `git@github.com:...` are the same remote
  written two ways.** Rewriting one form into the other is churn, not a repair.
  Preserve the form the file already uses.
- **A local path URL is not a stale URL.** A submodule pinned by a filesystem
  path - legal, and used for repositories that are not hosted - has no owner and
  name to canonicalise.

## Claim-to-test

| Claim | Probe | Pass condition |
| --- | --- | --- |
| No declared URL redirects | the `curl` loop above | no `redirect:` lines |
| The rewrite changed only URLs | `git diff --stat` on the `.gitmodules` files | changed lines are `url =` lines only |
| Line endings survived | `git diff --ignore-cr-at-eol --stat` | no whole-file rewrite |
| Submodule keys survived | `git config -f .gitmodules --get-regexp '\.(ignore|shallow|branch)$'` | same entries as before |
