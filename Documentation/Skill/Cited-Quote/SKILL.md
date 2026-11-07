---
name: cited-quote
description: "Use when prose quotes a figure or a literal that lives in a primary source."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [macos, linux]
category: Release
metadata:
  hermes:
    tags: [figures, quotes, citations, invented, verbatim]
    related_skills: [manifest-surface, version-parity]
---

# Cited Quote

A page states a number. A document shows a sample line. Both came from somewhere,
and both are retyped rather than read.

Worked instance: `PlayForm/Aphrodite`, `Site/Scripts/Drift-Guard.mjs`, sections 4
and 5 - every `Nx` figure a page carries is looked up in the README or the
CHANGELOG, and every stream-pane sample line in the docs' preview catalog.

## The invariant

**Every figure and every quoted literal in a derived surface exists in the primary
source it cites.**

Two data types, one relation: the quote must be findable in the source. A figure
that appears nowhere is invented; a figure that appears only rounded is not the
one the source states.

## The failure it prevents

A page carries `610×`. The README says `610×`. The CHANGELOG, which is the primary
for that figure, says `609.87×`. Nothing is obviously wrong, and the page now
states a number no source supports - so a reader who checks it finds a
discrepancy, and the discrepancy is in the page.

The sample-line form is the same failure with worse consequences: a documentation
page shows a stream pane containing a line the product never emits. A reader
builds a parser against it, and the parser is correct and useless.

The third form is a figure that was true and is not any more. The source changed,
the page did not, and the page is the one people read.

## The probe

Collect the quoting tokens from the derived surface, then look for each in the
primary:

```sh
grep -ohE '\b[0-9]+(?:[.,][0-9]+)?×' <pages>/* | sort -u |
  while read -r Figure; do
    grep -qF "$Figure" <primary-a> <primary-b> || echo "unsourced figure: $Figure"
  done
```

For quoted literals, build the catalog from the corpus first and compare against
it, rather than grepping per line:

```sh
grep -ohE '\[[a-z_]+:.*\]' <corpus>/*.md | sed 's/[[:space:]]*$//' | sort -u > /tmp/catalog
grep -ohE '\[[a-z_]+:.*\]' <pages>/* | sed 's/[[:space:]]*$//' | sort -u > /tmp/quoted
comm -13 /tmp/catalog /tmp/quoted
```

A line on the right is a quote with no source.

## The repair

Replace the quote with the source's value, or change the source and regenerate.
Which one is right depends on which side is authoritative - and a page is almost
never the authority.

Where the page deliberately rounds, state the rounding so the reader can see it is
a presentation choice rather than a claim.

## Pitfalls

- **A rounded figure is not the source's figure.** `133×` and `132.82×` are
  different strings; a containment check passes only if the page quotes the
  source's own text.
- **A secondary source may be the primary for a specific figure.** A page that
  cites a changelog anchor must match the changelog, not the README, even when the
  README also carries the number in a different form. Name the primary per figure.
- **A template fragment is not a quote.** `${...}` inside generated markup is
  interpolation, not a sample; a catalog built without excluding it fills with
  non-samples and the comparison becomes noise.
- **A sample line may carry trailing commentary.** Sources often append a note
  after the sample, so an anchored match finds nothing. Match the sample and trim.
- **An empty catalog passes every comparison.** Assert a minimum size on the
  catalog before comparing, or a broken extractor reports a clean surface.
- **A block label is not a sample.** Directive, nudge and recall prefixes belong
  to the system that emits them; judging them against a content catalog flags
  correct text. Exclude them by name.

## Claim-to-test

| Claim | Probe | Pass condition |
| --- | --- | --- |
| Every figure is sourced | the figure loop above | no `unsourced figure` lines |
| Every quoted literal exists | `comm -13` above | no lines |
| The catalog is real | its line count | at least the number of canonical shapes |
| The guard can fail | add an invented figure and re-run | the guard reports it |
| The right primary was used | the citation in the page | it names the file that was searched |
