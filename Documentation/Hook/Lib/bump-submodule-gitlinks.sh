#!/usr/bin/env bash
# Lib/bump-submodule-gitlinks.sh - shared by post-commit / post-merge /
# post-checkout / pre-push. Runs in a PARENT repository only.
#
# After any parent git action, if a tracked submodule's recorded gitlink differs
# from that submodule's HEAD, stage and commit the pointer update. Left alone,
# the parent records a commit the submodule is not on, a fresh clone checks out
# the wrong tree, and the mismatch surfaces later as a build failure in a file
# that exists in only one of the two.
#
# Each guard below exists because its absence produced a phantom gitlink:
#  1. Skip when this repository is itself a submodule - the parent owns the bump.
#  2. Only ever stage paths declared in .gitmodules whose index entry is a
#     genuine gitlink (mode 160000). Never `git add .`.
#  3. A recursion guard, so the nested commit cannot re-enter post-commit.
#  4. Skip mid-merge / mid-cherry-pick / mid-rebase; that commit records us.
#  5. No-op when no pointer changed - `git diff HEAD` honours `ignore = dirty`,
#     so a dirty worktree is never mistaken for a pointer update.
set -euo pipefail

# Guard 3: recursion - the nested commit below re-enters post-commit.
if [[ -n "${GITLINK_BUMP_ACTIVE:-}" ]]; then
	exit 0
fi

# Guard 1: a superproject exists, so this checkout is a submodule.
if [[ -n "$(git rev-parse --show-superproject-working-tree 2> /dev/null || true)" ]]; then
	exit 0
fi

ROOT="$(git rev-parse --show-toplevel)"

[[ -f "$ROOT/.gitmodules" ]] || exit 0

# Guard 4: mid-operation states - the parent's own commit will record us.
GITDIR="$(git rev-parse --absolute-git-dir)"
for STATE in MERGE_HEAD CHERRY_PICK_HEAD REBASE_HEAD; do
	if [[ -f "$GITDIR/$STATE" ]]; then
		exit 0
	fi
done

# Guard 2: enumerate real submodules - .gitmodules paths whose index entry is a
# genuine gitlink. Anything else is never touched.
SUBMODULES=()
while IFS=' ' read -r key path; do
	[[ -n "$path" ]] || continue
	mode="$(git ls-files -s -- "$path" 2> /dev/null | awk '{print $1}')"
	[[ "$mode" == "160000" ]] || continue
	SUBMODULES+=("$path")
done < <(git config -f "$ROOT/.gitmodules" --get-regexp '\.path$' 2> /dev/null)

# Guard 5: only changed pointers.
DIRTY=()
for SUB in "${SUBMODULES[@]:-}"; do
	if ! git diff --quiet HEAD -- "$SUB" 2> /dev/null; then
		DIRTY+=("$SUB")
	fi
done

if [[ ${#DIRTY[@]} -eq 0 ]]; then
	exit 0
fi

export GITLINK_BUMP_ACTIVE=1

git add -- "${DIRTY[@]}"

DETAILS=""
for SUB in "${DIRTY[@]}"; do
	NEW="$(git ls-files -s -- "$SUB" 2> /dev/null | awk '{print $2}')"
	DETAILS="$DETAILS $SUB@${NEW:0:7}"
done

# `--only` plus explicit paths: commit the pointer updates and nothing else.
# `|| true`: a transient failure (another writer holding the index) converges on
# the next parent git action.
git commit -o -m "chore: bump submodule gitlinks:$DETAILS" --no-verify -s -- "${DIRTY[@]}" > /dev/null 2>&1 || true
