# Drift

Drift guards, standardized. A guard is the invariant a repository must keep
between two things that are supposed to agree; this repository collects those
invariants in one shape and one place.

It holds no program. Each guard is a skill: the relation, the failure it prevents,
the exact command that proves it, and the repair.

---

## The one sentence

A drift guard is a relation between a **reference** and the things that must
agree with it, plus the rule that decides agreement.

That sentence is the whole taxonomy. Every guard here is an instance of it, and
the difference between two guards is only *which* thing is the reference and
*what* agreement means.

---

## Why a corpus and not a tool

The guards already existed, in five languages across four repositories, each with
its own output, its own exit code and its own idea of what "stale" means. A
person reading a failing check had to learn the tool that failed before learning
what had drifted.

A single binary would fix the output shape and break something else: it becomes a
runtime every repository has to depend on, and it cannot express the guards whose
repair is a decision rather than a computation. Which version is right, whether a
pin should move, and whether a pattern is an acceptable exception are not
questions a checker can answer.

So the corpus stores the judgement and the probe, and leaves execution to the
command each skill names. A guard is portable because it is prose plus a shell
line, and a reader can disagree with it.

---

## Categories

Four, by what disagrees with what.

**Git** - a repository disagrees with another repository, or with itself.

- `Submodule-Pin` - a recorded commit must be one the remote serves, and the
  checkout must sit on it.
- `Branch-Invariant` - a commit must land on a branch, because a commit on no
  branch cannot be found again.
- `Remote-Identity` - a declared URL must name the repository's current owner and
  name, not the one it had before a transfer.

**Derive** - a second form of one fact disagrees with the form it came from.

- `Mirror-Copy` - two copies written from one source cannot disagree.
- `Generated-Artifact` - a committed artifact must equal what its generator
  writes today, not what it wrote when the file was committed.
- `Round-Trip` - a conversion that claims to be reversible must reconstruct its
  input.
- `Duplicate-Declaration` - a fact written down twice is two facts, and they will
  stop agreeing.

**Tree** - a file disagrees with a rule about what may exist.

- `Public-Surface` - a public tree may contain no machine path, no real
  identifier and no internal note.
- `Ignore-Boundary` - an ignore rule must exclude only what nothing needs.
- `Import-Arrow` - a capability must not import the adapter that implements it.
- `Workspace-Membership` - every package directory is a member, and every member
  exists.

**Release** - a statement about the product disagrees with the product.

- `Version-Parity` - every declaration of the version must agree.
- `Claim-Evidence` - every status claim names the artifact that proves it.

---

## How a guard is written

Each skill carries the same five sections, in the same order, so a reader learns
the shape once:

- **The invariant** - one sentence, stated as a relation.
- **The failure it prevents** - what actually goes wrong, in a way a reader can
  recognise from a symptom rather than from the rule.
- **The probe** - the command, byte-stable, with the output that means drift.
- **The repair** - what to change, or why there is nothing mechanical to change.
- **Pitfalls** - the ways the probe lies: a measurement that reports a defect
  that is not there, or passes over one that is.

A guard with no probe is a preference. A probe that cannot fail proves nothing.

---

## What this repository is not

It is not a test suite, and it is not a CI gate. A guard is something a person
runs when they need the answer, and something an agent reads before it makes a
change. Wiring a guard into a pipeline is a separate decision that belongs to the
repository being guarded.

---

## Layout

- `AGENTS.md` - orientation, and the task-to-skill table.
- `Documentation/Skill/<Name>/SKILL.md` - one guard per directory.
- `Documentation/Hook/` - the preventive half: the git hooks two of the skills
  install, as one directory, because `core.hooksPath` names one directory.
- `Documentation/Skill/<Name>/Reference/` - archived instances, with an
  `Index.md` naming them, when a skill has any.
