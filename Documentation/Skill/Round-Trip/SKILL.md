---
name: round-trip
description: "Use when a conversion is supposed to lose nothing on the way back."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [macos, linux]
category: Derive
metadata:
  hermes:
    tags: [round-trip, projection, serialize, parse, fingerprint]
    related_skills: [generated-artifact, mirror-copy]
---

# Round Trip

Every conversion between two representations makes a promise. When the promise is
that the conversion is reversible, the promise is checkable, and it is the only
thing that makes a second format trustworthy.

## The invariant

**Converting to a form and back reconstructs the original, compared by a
canonical fingerprint.**

Written as two laws, because a detour through both forms must also be stable:

```text
decode(encode(x)) = x
encode(decode(y)) = y
```

A system that projects one model into several representations states a law per
projection, and the laws are the specification.

## The failure it prevents

A projection is lossy in a way nobody wrote down. A relation the target format
cannot carry disappears silently: the export succeeds, the import succeeds, and
the reconstructed model is missing an edge. Nothing errors, because nothing was
wrong at either step - the loss happened in the gap, and the gap is exactly what
a round-trip law measures.

The same shape appears far from data models:

- A serializer that drops a default value, so a round trip changes the file and
  the next diff is noise.
- A formatter that reflows code, so a round trip through it rewrites a file it
  was only supposed to read.
- A generator whose output cannot be parsed back by its own reader, so the
  artifact is write-only.

## The probe

Fingerprint, convert, convert back, fingerprint again. Compare fingerprints, not
text: a fingerprint is order-independent when the model is, and text is not.

```sh
<tool> fingerprint <source> > /tmp/before
<tool> encode <source> > /tmp/encoded
<tool> decode /tmp/encoded > /tmp/back
<tool> fingerprint /tmp/back > /tmp/after
diff /tmp/before /tmp/after
```

An empty diff proves the law for that input. One input proves very little, so run
the corpus, not one example:

```sh
for f in <corpus>/*; do
  <tool> fingerprint "$f" > /tmp/a
  <tool> decode <(<tool> encode "$f") > /tmp/back
  <tool> fingerprint /tmp/back | diff -q /tmp/a - > /dev/null || echo "law fails: $f"
done
```

A failure names the input, which is the whole diagnosis: the relation that input
carries is one the target format cannot represent.

## The repair

Either teach the target format to carry the relation, or remove the relation from
the model. The third option - documenting the loss and moving on - is only
correct when the law is restated to exclude that relation, and the exclusion is
named where the law is stated.

A lossy projection that nobody claims is reversible is fine. A projection that
claims reversibility and is not is the defect, and the claim is what makes it one.

## Pitfalls

- **Text equality is not model equality.** Field order, whitespace and numeric
  formatting differ between two encodings of the same model. Compare a canonical
  fingerprint over the model, not the bytes.
- **A fingerprint that ignores body text cannot detect a body edit.** If the
  digest covers only keys and names, a round trip that loses a body still passes.
  State what the fingerprint covers, and cover what the law is about.
- **A default value is a declaration.** A serializer that omits a default and a
  parser that restores it will round-trip, until the default changes - then the
  old file silently means something new.
- **One passing example is a coincidence.** The law is over the corpus. Run it
  over every input the system ships, and over the inputs that carry the rarest
  relation.
- **A round trip through a formatter can be lossy in the formatter's own way.**
  Line width, quote style and trailing commas are the formatter's decisions; a
  law that requires byte identity will fail for reasons that are not defects, and
  a law that ignores them will miss a lost comment.

## Claim-to-test

| Claim | Probe | Pass condition |
| --- | --- | --- |
| The projection is reversible | fingerprint before and after the round trip | identical fingerprints |
| The law holds over the corpus | the loop above | no `law fails` lines |
| The detour is stable | encode, decode, encode again | the second encoding equals the first |
| The fingerprint covers what the law claims | read the fingerprint function | it hashes every field the law names |
