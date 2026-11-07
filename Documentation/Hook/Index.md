# Hook - Reference

The preventive half of two guards, as one installable set.

---

The five hooks and the script they share are one directory because
`core.hooksPath` names one directory. A hook that resolves a path outside it
breaks the moment the repository is cloned somewhere else, so the set is
self-contained on purpose: `post-checkout` calls `Lib/bump-submodule-gitlinks.sh`
beside it, by the hook's own directory rather than by a path from the repository
root.

The set covers two skills, and installing only half of it leaves a guard that
fires after the drift it was meant to prevent:

- **`Branch-Invariant`** - `pre-commit` refuses a commit on a detached `HEAD`;
  `post-checkout` re-attaches one when a branch contains the commit.
- **`Submodule-Pin`** - `post-commit`, `post-merge` and `pre-push` call
  `Lib/bump-submodule-gitlinks.sh`, which records a moved submodule pointer.

---

## Installing

Copy the directory into the repository, under the name `core.hooksPath` will
name, and make the files executable. The scripts are bash and use process
substitution, so they are checked with `bash -n` rather than `sh -n`.

```sh
cp -R Documentation/Hook <repository>/.githooks
chmod +x <repository>/.githooks/pre-commit <repository>/.githooks/post-checkout \
  <repository>/.githooks/post-commit <repository>/.githooks/post-merge \
  <repository>/.githooks/pre-push <repository>/.githooks/Lib/bump-submodule-gitlinks.sh
git -C <repository> config core.hooksPath .githooks
```

Verify the wiring, then prove one hook fires:

```sh
git -C <repository> config --get core.hooksPath
```

```sh
git -C <repository> checkout --detach
git -C <repository> commit --allow-empty -m probe
```

The second command must be refused with the re-attach message, and the commit
must not exist afterwards. Then re-attach the repository to its branch.

## Line endings

An extensionless hook with CRLF line endings never runs: the shebang becomes
`env: bash\r` and the interpreter is not found, while the file still looks
installed. Pin the paths in `.gitattributes`:

```
Documentation/Hook/** text eol=lf
```
