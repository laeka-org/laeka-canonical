---
title: Matrix 1 -- Technical Stress (TEMPLATE)
claim_under_test: "[State the claim exactly as it would appear in the publication title or abstract. One sentence. No hedging here -- hedging comes later after matrix review.]"
date: [YYYY-MM-DD]
reviewer: [name or role of the person running this matrix]
status: [draft / analyzed / closed]
---

# Matrix 1 -- Technical Stress

**Scope**: sixty-four configurations structurally different from the proposed measurement or experiment. For each cell: expected behavior, current verdict, and narrowing prescribed if the claim fails at that cell.

**Claim under test**: [restate the full claim as it would appear in the publication, at the level of specificity that permits testing]

**Scoring rubric**: each cell receives one of:
- **PASS**: the claim holds in this cell (empirical support exists, or the cell is passive / config-enforced)
- **FAIL-HARD**: the claim breaks structurally and cannot be addressed by narrowing
- **FAIL-SOFT**: the claim breaks but a clean narrowing is prescribed
- **UNVERIFIED**: cell requires an experiment not yet run; cannot be resolved by reasoning alone

**Pass criterion for the matrix**: at minimum 75% of cells must be PASS or FAIL-SOFT (with narrowings accepted as part of the publication). No cell may be FAIL-HARD. UNVERIFIED cells must be either run before publication or explicitly declared as open limitations.

---

## Axis 1 -- [Variable rotation, e.g., "Model rotation" for ML claims, "Reagent variation" for biochem]

Claim: [one-line restatement of what this axis tests]

| Cell | Configuration | Expected | Verdict | Narrowing if broken |
|------|---------------|----------|---------|---------------------|
| 1.1 | [baseline configuration] | [expected outcome] | [PASS/FAIL-HARD/FAIL-SOFT/UNVERIFIED] | [what the claim narrows to if this fails] |
| 1.2 | [perturbation 1] | [expected] | [verdict] | [narrowing] |
| 1.3 | [perturbation 2] | [expected] | [verdict] | [narrowing] |
| 1.4 | [perturbation 3] | [expected] | [verdict] | [narrowing] |
| 1.5 | [perturbation 4] | [expected] | [verdict] | [narrowing] |
| 1.6 | [perturbation 5] | [expected] | [verdict] | [narrowing] |
| 1.7 | [perturbation 6] | [expected] | [verdict] | [narrowing] |
| 1.8 | [perturbation 7] | [expected] | [verdict] | [narrowing] |

**Axis 1 verdict**: [summary of cell results and critical-path cells that must run before publication]

---

## Axis 2 -- [Prompt / protocol perturbation]

Claim: [restatement]

| Cell | Configuration | Expected | Verdict | Narrowing if broken |
|------|---------------|----------|---------|---------------------|
| 2.1 | | | | |
| 2.2 | | | | |
| 2.3 | | | | |
| 2.4 | | | | |
| 2.5 | | | | |
| 2.6 | | | | |
| 2.7 | | | | |
| 2.8 | | | | |

**Axis 2 verdict**:

---

## Axis 3 -- [Input / response perturbation]

Claim:

| Cell | Configuration | Expected | Verdict | Narrowing if broken |
|------|---------------|----------|---------|---------------------|
| 3.1 | | | | |
| 3.2 | | | | |
| 3.3 | | | | |
| 3.4 | | | | |
| 3.5 | | | | |
| 3.6 | | | | |
| 3.7 | | | | |
| 3.8 | | | | |

**Axis 3 verdict**:

---

## Axis 4 -- Scale stress

Claim:

| Cell | Configuration | Expected | Verdict | Narrowing if broken |
|------|---------------|----------|---------|---------------------|
| 4.1 | [smallest N] | | | |
| 4.2 | [small N] | | | |
| 4.3 | [current N / baseline] | | | |
| 4.4 | [next scale up] | | | |
| 4.5 | [further scale] | | | |
| 4.6 | [production scale] | | | |
| 4.7 | [session / duration stress] | | | |
| 4.8 | [burst / parallelism stress] | | | |

**Axis 4 verdict**:

---

## Axis 5 -- Context rotation

Claim:

| Cell | Configuration | Expected | Verdict | Narrowing if broken |
|------|---------------|----------|---------|---------------------|
| 5.1 | [baseline context] | | | |
| 5.2 | [adjacent context] | | | |
| 5.3 | [different language] | | | |
| 5.4 | [different role or agent type] | | | |
| 5.5 | [ ] | | | |
| 5.6 | [ ] | | | |
| 5.7 | [ ] | | | |
| 5.8 | [ ] | | | |

**Axis 5 verdict**:

---

## Axis 6 -- Timing perturbation

Claim:

| Cell | Configuration | Expected | Verdict | Narrowing if broken |
|------|---------------|----------|---------|---------------------|
| 6.1 | [t = 0 baseline] | | | |
| 6.2 | [t + 1 hour] | | | |
| 6.3 | [t + 24 hours] | | | |
| 6.4 | [t + 1 week] | | | |
| 6.5 | [t + 1 month] | | | |
| 6.6 | [temperature or seed sensitivity] | | | |
| 6.7 | [batch vs. individual] | | | |
| 6.8 | [cold start vs. warm start] | | | |

**Axis 6 verdict**:

---

## Axis 7 -- Cross-instance variance

Claim:

| Cell | Configuration | Expected | Verdict | Narrowing if broken |
|------|---------------|----------|---------|---------------------|
| 7.1 | [baseline run] | | | |
| 7.2 | [same N different temperature] | | | |
| 7.3 | [run at T = 0] | | | |
| 7.4 | [different system prompt or protocol variant] | | | |
| 7.5 | [3 independent instances on same inputs -- inter-rater alpha] | | | |
| 7.6 | [cross-family or cross-instrument] | | | |
| 7.7 | [snapshot / version pinning] | | | |
| 7.8 | [human inter-rater on representative sample] | | | |

**Axis 7 verdict**:

---

## Axis 8 -- Adversarial injection

Claim:

| Cell | Configuration | Expected | Verdict | Narrowing if broken |
|------|---------------|----------|---------|---------------------|
| 8.1 | [basic prompt or protocol injection] | | | |
| 8.2 | [self-praise / sycophancy injection] | | | |
| 8.3 | [off-distribution input] | | | |
| 8.4 | [obfuscation or homoglyph attack] | | | |
| 8.5 | [extreme length input] | | | |
| 8.6 | [rubric-rewriting input] | | | |
| 8.7 | [parser / format injection] | | | |
| 8.8 | [overfitting to few-shot examples] | | | |

**Axis 8 verdict**:

---

## Summary -- Matrix 1 scoring

| Axis | PASS | FAIL-HARD | FAIL-SOFT | UNVERIFIED |
|------|------|-----------|-----------|-------------|
| 1. | | | | |
| 2. | | | | |
| 3. | | | | |
| 4. | | | | |
| 5. | | | | |
| 6. | | | | |
| 7. | | | | |
| 8. | | | | |
| **Total** | | | | |

## Critical finding

[Summarize the critical cells that block publication and the estimated cost to run them.]

## Must-run cells before publication

[List the cells that have the highest criticality-to-cost ratio. These are the minimum experiments to run before any claim of reproducibility can be sustained.]

## Narrowing recommendations

[Restate the claim in the narrowest form that survives every cell marked PASS or FAIL-SOFT. This is the claim that can be published today if the UNVERIFIED cells are not run.]

## Estimated time to un-break Matrix 1

- Critical cells: [hours, API or materials budget]
- Full Matrix 1: [hours, budget]
- Extensions: [what would be covered by additional experiments]
