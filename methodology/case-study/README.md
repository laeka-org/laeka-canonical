# Case Study -- Refused Datapoint

This directory contains the four matrix analyses and the verdict document from the pre-publication review that refused publication of a proposed empirical claim on 2026-04-17. The claim and its refusal are the worked example for the protocol described in `../PRE-PUBLICATION-MATURATION-PROTOCOL.md`.

## Contents

- [`matrix-1-technical.md`](matrix-1-technical.md) -- sixty-four technical stress cells, eight axes. Twenty-one percent PASS, seventy-eight percent UNVERIFIED. Identifies seven must-run cells before publication.
- [`matrix-2-adversarial.md`](matrix-2-adversarial.md) -- sixty-four adversarial attacks from eight archetype critics, each with a dissolution under two hundred words. Fifty-one percent of attacks require the claim to narrow.
- [`matrix-3-audience.md`](matrix-3-audience.md) -- sixty-four reader registers. Twenty-two percent PASS, thirty-six percent PARTIAL, forty-two percent FAIL. Three candidate reformulations proposed.
- [`matrix-4-cosmological.md`](matrix-4-cosmological.md) -- four lenses times sixteen dimensions. All four lenses scored between sixty-six and seventy-three percent, below the seventy-five percent threshold.
- [`verdict.md`](verdict.md) -- synthesis and the `CONTINUE-MATURATION` decision.

## What was refused

A proposed publication that would have announced the first operational dataset produced by the lab's live integrity scorer as an empirical datapoint for a broader methodology claim. One session, one hundred and eighty-five scored responses, one subject model, one scorer model, one operator.

The refusal was not of the tool (which continues to operate) nor of the methodology (which is documented and published as a proposal in `../../benchmark/methodology.md`). The refusal was specifically of the framing that would have positioned the dataset as a validated empirical result.

## What is anonymized

- Internal commit SHAs and file paths specific to the lab's private infrastructure are replaced with generic references.
- The individual operator's name is not used; the protocol applies regardless of who produced the claim.
- The scored dataset itself is not released in this directory; that release is gated on completion of the remediation work documented in the verdict. A sample of thirty anonymized messages will be released alongside the tool's eventual publication.

## What is not anonymized

- The specific models used (Claude Opus 4.7 as subject, Claude Haiku 4.5 as scorer), because model identity matters for reproducibility discussion.
- The specific date (2026-04-17), because versioning discipline requires it.
- The structural failures identified in each matrix, because the point of the case study is that these failures are typical and recognizable.

## How to read the case study

The most informative entry points are:

- `matrix-1-technical.md` -- read first if you want to see what empirical verification the protocol demands.
- `matrix-2-adversarial.md` -- read second if you want to see what kinds of attacks a claim must either dissolve or narrow under.
- `verdict.md` -- read last for the synthesis and the `CONTINUE-MATURATION` decision.

The case study is a record, not a recommendation. Your own claim, even in the same domain, will produce different cells, different failures, and potentially a different verdict. The protocol is the transferable artifact; the case study is one instance of it in operation.
