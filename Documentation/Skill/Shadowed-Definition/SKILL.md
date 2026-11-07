---
name: shadowed-definition
description: "Use when two paths define the same name and only one of them takes effect."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [macos, linux]
category: Tree
metadata:
  hermes:
    tags: [precedence, shadowing, duplicate, lookup, load-order]
    related_skills: [duplicate-declaration, renamed-reference]
---

# Shadowed Definition

A name is defined in two places. A loader resolves it in a fixed order. One copy
takes effect and the other is never read - and the one that is never read is
often the one being edited.

## The invariant

**A definition that exists is the definition in effect, or it does not exist.**

The stronger form: **one name resolves to one definition, and the file that holds
it is the file the loader reports.**

## The failure it prevents

Two skill directories described the same skill. Edits went into the one the
loader did not read, so the behaviour never changed and the diff looked correct.
The symptom was not an error - it was work that had no effect.

The same shape appears wherever a lookup has an order:

- A repository's own skill directory shadows the user-level one of the same name,
  so a profile-level edit silently does nothing inside that repository.
- A startup file loaded later overrides an earlier one, so a variable set in both
  takes the later value - and the earlier line reads as authoritative because it
  is the one a person greps for.
- A re-export shadows a crate of the same name, so `use Adapter::Serves` resolves
  to the trait rather than the module and the compiler answers "not a module".
- A copy kept in an archive directory sits beside the live one and is edited by
  mistake, because the two paths differ by one segment.

## The probe

Ask the loader, not the filesystem. The filesystem can only tell you that two
paths exist; only the loader knows which one won.

```sh
<tool> which <name>          # or: list / resolve / --show-config, whichever the tool has
```

Then compare the answer with the paths you know about:

```sh
find . -name '<name>' -not -path '*/node_modules/*' | sort
```

More hits than the loader reported is the defect: the extras are shadowed. For a
lookup defined by an ordered list, read the order rather than guessing it:

```sh
grep -rn 'precedence\|load order\|PROJECT_SKILLS\|trusted' <loader source>
```

For a name resolved by a shell, the effective value is the only evidence:

```sh
<shell> -lic 'echo $NAME'
```

## The repair

Delete the copy that cannot take effect, or move it into the precedence position
if it is the one that should win. Keeping both and remembering which is live is
not a repair: it is a rule that lives in one person's head and fails the first
time somebody else edits.

Where the duplicate is deliberate - a template, a fixture, an archive - make it
unmistakably not a definition: a different extension, a directory the loader
skips, or a header that states it is not loaded.

## Pitfalls

- **A stale copy in an archive is harmless until it is not.** A directory the
  loader skips becomes a directory it reads the day the skip rule changes. Check
  the skip rule, not the directory name.
- **A case-insensitive filesystem can make two paths one.** On macOS, `Skill/`
  and `skill/` may be the same directory; a "duplicate" found by a case-sensitive
  comparison does not exist, and a rename that assumed they were distinct does
  nothing.
- **The loader's report can be silent about what it skipped.** A tool that lists
  only what it loaded cannot tell you what it ignored. Look for a diagnostic verb
  (`doctor`, `status`, `--verbose`) before concluding there is no duplicate.
- **A shadowed definition still passes its own tests.** The test imports by
  relative path, so it exercises the copy the loader would skip. A green suite is
  not evidence that the live path is the one under test.
- **Editing the file the loader names is not the same as editing the file you
  opened.** After a rename or a move, confirm the path the loader resolves to
  before making an edit, not after.

## Claim-to-test

| Claim | Probe | Pass condition |
| --- | --- | --- |
| One definition per name | the `find` above | one hit, or every extra is skipped by the loader |
| The live definition is the edited one | the loader's resolve verb | its path equals the edited path |
| The edit took effect | observe the behaviour, not the file | the change is visible |
| The skip rule is explicit | the loader's configuration | the skipped paths are named |
| No archive is live | the loader's list of roots | the archive directory is absent |
