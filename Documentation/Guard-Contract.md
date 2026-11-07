# Guard Contract

How a guard is written, so that a reader who has read one can read all of them,
and so that a new guard is added without inventing a shape.

---

## The relation

Every guard is one sentence with three parts:

```text
<reference> and <the things that must agree with it> agree by <the rule>.
```

- **The reference** is the side that is right by construction: the first path, the
  producer's output, the remote, the first declared value, the contract itself.
- **The things that must agree** are the copies, the artifacts, the pins, the
  other declarations, the files the rule is about.
- **The rule** is the measurement: byte equality, reachability, set equality,
  existence, absence, an exit code.

If the sentence cannot be written, the guard is not a drift guard. A preference, a
style rule and a completeness goal are all worth having; none of them is a
relation between two things.

---

## The five sections

Same order, every skill, because the order is the reading path.

**The invariant** - the relation, in bold, in one sentence. Nothing else in this
section.

**The failure it prevents** - what actually goes wrong, written so a reader
recognises it from a symptom. Two or three instances, each a different way the
same relation breaks. No rule is repeated here; this section is about what a
person sees.

**The probe** - the command, and the output that means drift. Byte-stable:
flags, paths and identifiers copied exactly, placeholders where a path is a
variable. A probe with no command is a suggestion.

**The repair** - what to change, or a statement that there is nothing mechanical
to change and why. A guard whose repair is a judgement says so; it does not
pretend to be automatable.

**Pitfalls** - the ways the probe lies. A measurement that reports a defect that
is not there, or passes over one that is. This section is the one that earns the
guard its place: without it the probe is a command somebody ran once.

Then a **Claim-to-test** table: one row per claim, the probe that settles it, and
the pass condition.

---

## The four rules a probe must satisfy

1. **It must be able to fail.** A probe that cannot fail proves nothing. Add the
   defect by hand once and watch the probe report it.
2. **It must fail for the right reason.** A green result from an extractor that
   matched nothing is the worst outcome: it is indistinguishable from agreement.
   Assert a minimum size on every extracted side before comparing.
3. **It must compare the thing the claim names.** A count is not a set. A
   timestamp is not a content hash. A word boundary is not a substring. State the
   comparison the invariant asks for, not the cheapest one that compiles.
4. **It must skip, not fail, when its primaries are absent.** One tree can be
   checked in two checkouts - a monorepo and a standalone deploy - and a guard
   that fails because its sources are not there gets disabled, which is worse than
   not existing. Report `skipped`, and name what was missing.

---

## Skeleton

```markdown
---
name: <directory name, lowercased>
description: "Use when <trigger>. <what it does>."
version: 1.0.0
category: <Git | Derive | Tree | Release>
---

# <Title>

<One paragraph: what the two sides are and why they are maintained separately.>

## The invariant

**<The relation, one sentence.>**

## The failure it prevents

<The symptom a reader recognises. Two or three instances.>

## The probe

<The command, byte-stable. The output that means drift.>

## The repair

<What to change, or why nothing mechanical exists.>

## Pitfalls

- **<The way the probe lies.>** <What to do instead.>

## Claim-to-test

| Claim | Probe | Pass condition |
| --- | --- | --- |
| <claim> | <command> | <observable state> |
```

---

## Anti-patterns

- **A count where the invariant asks for a set.** `13 == 13` is true for two
  different thirteens, and it stays true when one item is added and another
  removed in the same change.
- **A probe that asserts existence rather than agreement.** A `data-*` attribute
  present on a rendered element proves the template ran; it does not prove the
  value was compared.
- **A guard that relaxes itself to stay green.** A subset check, an `allow` list
  that grows, a skip whose condition is "it failed before" - each converts a
  visible disagreement into an invisible one.
- **A repair that guesses.** A version disagreement, a phantom pin and a forbidden
  pattern all need a decision. A repair that picks one side is worse than a report
  that names both.
- **A rule stated twice.** If two skills carry the same rule, they will disagree.
  One skill states it; the other links to it.
- **A worked instance inlined instead of pointed at.** The rule goes in the body;
  the instance goes in `Reference/`, or the body becomes a case study that is
  right about one tree and wrong about the next.
