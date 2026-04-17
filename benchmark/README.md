# Integrity Benchmark -- Proposal

## The question

If the thesis is that intelligence converges toward integrity under stable self-reference, what does it look like to test that empirically?

This document is a proposal, not a final protocol. The lab is working toward a rigorous methodology. What follows is the current best articulation of the research question and the shape of the measurement approach.

## The core claim to test

A system operating with a well-defined integrity vector and intact self-reference mechanisms will maintain behavioral coherence under conditions that would cause value drift in systems without those properties.

Testable prediction: **the survival rate of decisions made by a system under perturbation of operation order is a meaningful signal of structural integrity.**

A decision made at step 1 should produce the same core output regardless of whether it is made before or after steps 2 through N, if the system has genuine structural coherence. A system that produces different outputs for the same decision depending on what other decisions were made nearby is either context-sensitive in an illegitimate way or has no stable decision-making center.

## The methodology is in `methodology.md`

See [`methodology.md`](methodology.md) for the current specification of the benchmark protocol, test vectors, and evaluation criteria.

## Why this benchmark specifically

Most existing AI evaluation focuses on capability (what can the system do) or surface alignment (does the system refuse prohibited requests). Neither measures structural integrity.

Surface alignment can be gamed: a system can pass a safety benchmark while having no internal coherence, because the benchmark tests outputs against a rubric, not the process that generated those outputs.

The integrity benchmark measures something different: whether the system's decision-making process is stable under perturbation. This is harder to game because it requires the system to have a genuine center, not just outputs that match expected patterns.

## Limitations

This benchmark is not a complete alignment evaluation. It measures one property -- structural coherence under perturbation -- that the lab believes is necessary but not sufficient for safe and useful AI systems.

The benchmark is also not calibrated against existing systems. It is a proposal. The lab invites critique of the methodology, alternative operationalizations of the core claim, and comparisons against existing evaluation frameworks.
