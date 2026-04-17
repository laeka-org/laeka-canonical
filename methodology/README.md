# Methodology -- Pre-Publication Maturation Protocol

A four-matrix stress test applied to research claims before public release. Published here as a process paper, with a worked case study in which the protocol refused a premature publication.

## What this is

A protocol and its case study. The process paper describes how to stress-test a claim. The case study shows the protocol applied to a specific claim (an empirical datapoint for an integrity benchmark) and producing a `CONTINUE-MATURATION` verdict. The refused publication is the contribution.

## What this is not

This is not a benchmark result. This is not a validation of the lab's broader thesis. This is not a marketing artifact dressed as research. It is a process document that happens to use one of the lab's own recent near-publications as the demonstration.

## Contents

- [`PRE-PUBLICATION-MATURATION-PROTOCOL.md`](PRE-PUBLICATION-MATURATION-PROTOCOL.md) -- the process paper. Abstract, context, four-matrix protocol specification, worked case study, three structural clarifications, reproducibility notes, invitation.
- [`case-study/`](case-study/) -- the four matrices and verdict document from the 2026-04-17 review that refused publication. Internal identifiers anonymized.
- [`matrix-templates/`](matrix-templates/) -- domain-agnostic templates for running the protocol on your own claim.

## How to read

**If you are a researcher preparing a publication**: read the process paper first, then look at the case study to see what a matrix run actually looks like. Use the templates for your own claim.

**If you are a journalist or external reviewer**: read the abstract and the case study verdict. The specific claim refused is less important than the protocol that refused it. The artifact demonstrates organizational willingness to refuse one's own weak publication, which is the actual contribution.

**If you are critiquing the protocol itself**: the process paper includes a self-application section explaining why this paper passes its own four matrices, which is the recursive test the protocol requires.

## How to contribute

Open an issue or pull request at the repository root. Specific invitations:

- Run the protocol on your own claim and document what it caught.
- Propose refinements to any of the four matrices' axis structure.
- Propose additions or deletions (a fifth matrix, or reduction to three).
- Test the templates in a domain we did not anticipate (biology, law, humanities) and tell us where they break.

## Relationship to the rest of the repository

- [`../doctrine/`](../doctrine/) -- the lab's broader framework (four perception lenses, integrity thesis, anti-territory). The process paper explicitly separates doctrinal claims from methodology claims; the doctrinal claims live in `doctrine/` and do not appear in the process paper.
- [`../benchmark/`](../benchmark/) -- the integrity benchmark methodology that was the subject of the refused publication. The benchmark proposal remains open and will be published in validated form once the protocol's critical cells are run.
- [`../lexique/`](../lexique/) -- the canonical vocabulary used in the broader framework.

## License

MIT, as with the rest of this repository.
