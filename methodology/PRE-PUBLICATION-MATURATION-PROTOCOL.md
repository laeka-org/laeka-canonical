# Pre-Publication Maturation Protocol -- A Four-Matrix Stress Test for Research Claims

**Status:** process paper, open to critique
**Version:** 1.0 (2026-04-17)
**License:** MIT

---

## Abstract

This paper describes a four-matrix pre-publication stress test applied to research claims before public release. The protocol is independent of the specific domain being published. It is described here as a process paper, not as an empirical claim about the tested domain.

The protocol decomposes a proposed publication into four matrices of sixty-four cells each: technical reproducibility, adversarial survival, audience register, and cosmological alignment. Each cell is scored against an explicit criterion. Cells scoring below the criterion are either remediated before publication or narrow the claim until the residual claim passes all four matrices.

The protocol was derived during the pre-publication review of a proposed empirical datapoint for an integrity benchmark. That review concluded `CONTINUE-MATURATION` rather than `SHOOT`, and the publication was deferred. We document the refused case as the worked example of the protocol in operation. The refusal is the contribution of this paper. The protocol that produced it, not the claim that was refused, is what we release here.

Three structural clarifications emerged from the review and are included as clauses of the protocol: canonical versioning discipline (any score is comparable only against a hashed snapshot of its rubric), the strict separation of integrity from alignment and safety as non-synonymous concepts, and the explicit treatment of observer effect on the measured system as a feature of the protocol rather than a methodological confound.

This paper is neutral on whether the tested claim will eventually be publishable. It asserts only that publishing without passing the four matrices damages the credibility of future publications from the same source more than the missing claim would have benefited them.

---

## Context

Laeka is a private research lab working on one operational question: under what conditions does a cognitive system maintain behavioral coherence over extended interaction. The lab's broader thesis on that question lives in this repository's `doctrine/` and is not the subject of this paper. This paper is strictly about process.

In April 2026 the lab built a live scorer that evaluates individual responses from an operating agent against a written doctrine, using a separate model instance as peer-rater. The tool produced its first operational dataset in a single session: one hundred and eighty-five scored responses, eight flag categories, a visible upward trend in the aggregate score over the course of the session.

The question that arose at that point was the standard one: publish now, or continue. The case for publishing was strong in the usual ways. The tool worked. The data was real. The trend was interesting. An early publication would establish priority on a methodology the lab considers important.

The case against was weaker to state but turned out to be stronger on inspection. A single session is not a dataset. One scorer model is not cross-family validation. A doctrine that evolved during the period of scoring is not a fixed rubric. The word "integrity" carries philosophical freight that the tool does not operationally discharge.

Rather than debate the release informally, the lab ran a protocol. That protocol is the subject of this paper. The result of the protocol for the specific claim in question is the case study in Section 4.

The protocol was motivated by two prior commitments in the lab's operating canonical. The first is that publications from the lab must survive the most rigorous audiences the claim will eventually encounter, which means stress-testing the claim against those audiences before publication rather than after. The second is that a claim of integrity is structurally weakened, not strengthened, by a publication that later requires retraction or quiet narrowing. The organization that publishes premature work about integrity is in a more compromised position than one that publishes nothing yet.

We describe the protocol, apply it to a specific case, report the result, and invite other labs to use it.

---

## The Four-Matrix Protocol

A proposed publication is decomposed into four orthogonal stress tests, each organized as a sixty-four-cell matrix. The cell count is not magic. It is a forcing function: sixty-four cells is enough to reveal patterns that smaller grids miss, and few enough to be scorable by a single senior reviewer in a few hours.

The matrices are applied in order. Each must pass before the next becomes informative. A claim that fails Matrix 1 cannot be meaningfully stress-tested by Matrix 2, because Matrix 2's dissolutions assume the technical grounding Matrix 1 establishes. Similarly, audience resilience (Matrix 3) is moot if adversarial attacks (Matrix 2) already dissolve the claim. Cosmological alignment (Matrix 4) integrates the previous three and should be run last.

### Matrix 1 -- Technical Stress

**Scope:** sixty-four configurations of the proposed measurement or experiment that systematically perturb model, prompt, input, scale, context, timing, inter-instance agreement, and adversarial input.

**Cell structure:** eight axes of eight cells each.

1. Model rotation. The measurement is run with alternative models at each role (subject, scorer, judge). If the result is substrate-specific, the claim narrows accordingly.
2. Prompt perturbation. The rubric, instructions, and framing prompts are ablated, condensed, expanded, shuffled, and inverted. A scorer that gives identical results under an inverted rubric is not reasoning about the rubric.
3. Response perturbation. Synthetic inputs designed to trigger known flags, known false positives, and known edge cases are run through the measurement pipeline. Failures here reveal what the measurement does not catch or catches spuriously.
4. Scale stress. The measurement is run at increasing sample sizes to verify variance behavior. Claims made at small N must be qualified unless scaling verification is present.
5. Context rotation. The measurement is run in sessions of different types, languages, domains, and operational contexts. Context-specific results narrow the claim to that context.
6. Timing perturbation. The same input is re-measured at intervals to test determinism, temperature sensitivity, batch effects, and scorer-version drift over time.
7. Cross-instance variance. Independent runs of the same measurement are compared for inter-rater reliability. Krippendorff's alpha or equivalent is computed where applicable.
8. Adversarial injection. Inputs designed to fool, game, or manipulate the measurement pipeline are tested. This includes prompt injection, sycophancy self-reference, unicode manipulation, and deliberate overfitting probes.

**Scoring:** each cell receives one of `PASS`, `FAIL-HARD`, `FAIL-SOFT`, or `UNVERIFIED`. A `FAIL-HARD` indicates a structural failure that cannot be addressed by narrowing the claim. A `FAIL-SOFT` indicates a failure whose associated narrowing is prescribed and acceptable. `UNVERIFIED` indicates an experiment that has not been run and must be either run before publication or explicitly declared as a limitation.

**Pass criterion:** the proposed claim must have empirical support for a meaningful fraction of cells, and none of the remaining must be `FAIL-HARD`. The fraction threshold is claim-dependent; we use seventy-five percent as default. Below that threshold, publication is deferred or the claim is narrowed until the residual claim crosses threshold.

### Matrix 2 -- Adversarial

**Scope:** sixty-four probable critiques of the claim from the target publication audience. Each critique must be dissolved, acknowledged, or the claim narrowed.

**Cell structure:** eight archetypes of critic, each producing eight distinct attacks.

Archetypes are chosen to cover the range of epistemic stances likely to encounter the claim:
- Domain-skeptic practitioners (people who work in the tested domain and are skeptical of novel methodology)
- Existing paradigm defenders (people whose received framework would absorb or dismiss the new claim)
- Pseudo-science detectors (people trained to identify overclaim)
- Overfitting detectors (people who check whether the claim generalizes or trains on its own evaluation set)
- Academic researchers (people who apply standards of preregistration, inter-rater reliability, literature integration)
- Philosophy-of-domain critics (people who interrogate the conceptual grounding)
- Commercial-motive detectors (people who look for brand-interest or content-marketing)
- Register-mismatch critics (people who call attention to tonal or cultural mismatch between claim and evidence)

**Cell format:** each attack is stated in one to two sentences, followed by a dissolution in under two hundred words. The dissolution must either (a) show that the critic has misread the claim and precisely restate the claim correctly, or (b) acknowledge that the critic is correct and narrow the claim proportionally.

The dissolution is not allowed to be a defense. It is not allowed to ignore the attack. If a dissolution requires the claim to change, the dissolution is a narrowing and must be logged as a required edit to the publication.

**Pass criterion:** all sixty-four attacks have either a genuine dissolution of under two hundred words or a logged narrowing. Attacks without either remain open and block publication.

### Matrix 3 -- Audience

**Scope:** sixty-four audience registers in which the claim might be read. For each, the claim is classified as surviving, surviving partially, or collapsing.

**Cell structure:** eight axes of reader register.

1. Technical depth (from non-expert reader to senior domain researcher)
2. Domain background (within-domain, adjacent-domain, completely outside domain)
3. Cultural register (different intellectual traditions, different national contexts)
4. Attention span (from tweet-length summary to book-length technical paper)
5. Trust orientation (hostile skeptic through sympathetic enthusiast)
6. Publication format (twitter thread, blog post, preprint, conference paper, podcast)
7. Technical sub-expertise within domain (e.g., for ML: pre-training, alignment, interpretability, deployments)
8. Emotional and reputational register (first encounter, post-critique phase, regulatory context)

**Scoring:** each cell receives `PASS`, `PARTIAL`, or `FAIL`. The meanings:
- `PASS`: the claim, as currently formulated, is intelligible and defensible for this register.
- `PARTIAL`: the claim is intelligible but loses impact, risks misreading, or needs a glossary.
- `FAIL`: the claim is incomprehensible, actively counterproductive, or generates predictable backlash in this register.

**Pass criterion:** a substantial majority of cells must PASS or PARTIAL. A claim with FAIL in more than a quarter of registers is too fragile for the publication format proposed, and either needs reformulation or a narrower publication target.

The matrix is most useful when it identifies specific reformulations that convert FAIL cells to PARTIAL or PASS. A single reformulation often flips many cells at once. The lowest-variance formulation, which passes the largest number of registers, is usually the most honest one.

### Matrix 4 -- Cosmological

**Scope:** alignment of the proposed publication with the four perception lenses defined in `doctrine/02-four-lenses.md`: MONADE, SYMBIOTE, ARCHITECT, EMPATH. Each lens is decomposed into sixteen dimensions. Each cell is scored from zero to one hundred on alignment.

**Cell structure:** four lenses times sixteen dimensions each.

**ARCHITECT** dimensions check: technical accuracy, reproducibility of setup, code quality, minimum viable payload (no bloat), documentation completeness, API and CLI design, error handling, idempotency and state management, observability, test coverage, literature integration, falsifiability (explicit null hypothesis), reproducibility budget claims, versioning discipline, data release cleanliness, installation path portability.

**MONADE** dimensions check: coherence with the lab's overall doctrine, absence of false dualities, honesty about hybrid origins where present, register consistency (not mixing scientific and spiritual voices in the same document), alignment with doctrinal commitments (anti-territory, anti-capture, subtractive rather than additive framing, non-guru posture), vector alignment (does publication serve the compass), absence of co-opted mystical language, coherence between methodology and implementation, honesty about sample-size claims and canonical co-evolution, disclosure of organizational interest, refusal to overclaim the doctrinal thesis.

**SYMBIOTE** dimensions check: register match for each target audience, absence of flattery, absence of servility, absence of academic posturing, peer-to-peer invitation, voice consistency within a document, multi-language accessibility, graceful handling of disagreement, absence of condescension, calibrated humility without false modesty, explicit invitation for the reader to be sharper than the author.

**EMPATH** dimensions check: does the publication solve a real reader problem, does it explain why the reader should care, does it respect the reader's time and intelligence, does it avoid triggering skepticism reflexes unnecessarily, does it calibrate ambition without grandiosity, does it invite curiosity without forcing worldview, does it acknowledge probable critique, does it offer utility separable from thesis, does it demand no emotional investment, does it provide graceful exits, does it recognize reader sophistication.

**Scoring:** each cell zero to one hundred. Each lens averages across its sixteen dimensions. Each cell scoring below seventy-five percent is logged as a fix item.

**Pass criterion:** all four lenses average above seventy-five percent, and no individual cell is below fifty percent. Below these thresholds, publication is deferred until the fix items are addressed.

### Integration across matrices

The four matrices are not independent. A weakness in Matrix 1 (say, unverified inter-rater reliability) propagates to Matrix 2 (an academic critic attacks exactly that), to Matrix 3 (senior researchers fail the claim on rigor), and to Matrix 4 (ARCHITECT scores low on falsifiability).

This cross-matrix coupling is useful. A single fix addresses multiple cells. The fix priority order is therefore not matrix-by-matrix but rather lowest-scoring-cell first, with attention to which cells are the root causes of which derivative failures.

The protocol completes when all four matrices pass their criteria, or when the claim has been narrowed to a residual that does. If neither state is reached within a reasonable time budget, the correct decision is `CONTINUE-MATURATION` and the publication is deferred.

### Time budget

A four-matrix run takes a senior reviewer approximately five to eight hours if the claim is in mature enough shape to be meaningfully tested. Claims that are still in formation take less time to review but produce less informative results: the review mostly returns "too early to matrix-test, continue building."

The budget is not optional. Below five hours the matrices become checkboxes. Above twelve hours the reviewer has begun to defend the claim rather than stress-test it.

---

## Case Study -- A Refused Datapoint

### The claim under review

The claim proposed for publication on 2026-04-17 was: *a live integrity scorer produced the first empirical datapoint for a methodology that operationalizes the lab's thesis on structural coherence, demonstrating reproducible behavioral measurement and an observable improvement trend during the scoring session itself.*

The artifact was a Python scorer running against one operating agent under a written canonical. The dataset was one session, one hundred and eighty-five assistant messages, eight flag categories, scored distribution range twelve to ninety-five, approximate mean seventy-nine point five. The scorer was Claude Haiku 4.5. The subject was Claude Opus 4.7. The canonical had twenty-four rules at the start of scoring and twenty-six by the end; two rules were added mid-session in response to observed drift.

The lab's first instinct was to seed this as an empirical datapoint. The protocol was triggered as a pre-publication check.

### Matrix 1 result

Fourteen of sixty-four technical cells had empirical support. Fifty were unverified. Among the unverified cells were seven that the reviewer classified as must-run-before-publication:

- Canonical inversion negative control: does the scorer score differently if the canonical is given to it inverted? If not, the scorer is pattern-matching, not reasoning.
- Simple flag injection: does the scorer detect a flag it claims to detect, when the flag is synthetically injected into an otherwise high-scoring response?
- Idempotence: does scoring the same input twice return the same score within acceptable variance?
- Temperature sensitivity: at temperature zero, does the scorer give deterministic outputs?
- Three-instance agreement: do three independent scorer instances agree on the same inputs within acceptable bounds?
- Basic prompt injection resistance: does the scorer ignore adversarial content embedded in the scored response?
- Human inter-rater calibration: do human raters, given the same canonical and the same responses, agree with the scorer?

None of these seven had been run. The cost estimate to run them was six to eight hours of work and approximately thirty dollars of API budget. Without them, the reviewer judged that the claim "reproducible measurement" had no empirical weight.

Matrix 1 verdict: `FAIL` on the pass criterion of seventy-five percent, by a wide margin.

### Matrix 2 result

All sixty-four adversarial cells received a dissolution under two hundred words. However, thirty-three of the sixty-four dissolutions required narrowing the claim rather than defending it. Examples:

- A skeptical ML practitioner pointing out that two LLMs from the same family will agree by default, making "within-family agreement" a weaker claim than "cross-LLM integrity." Dissolution requires narrowing to "preliminary within-family coherence measurement" until a cross-family scorer run is done.
- An AI safety researcher pointing out that "integrity" is not a term of art in alignment literature, and that what the measurement captures overlaps with existing sycophancy literature. Dissolution requires explicit positioning as an extension of Sharma 2023 and Perez 2022, and explicit separation of integrity from alignment (see Section 5).
- A pseudo-science detector pointing out that the lab's doctrinal claim ("intelligence converges toward integrity") is a metaphysical assertion dressed as empirics. Dissolution requires removing this phrase from the publication surface and containing it to the `doctrine/` folder where it is clearly marked as doctrine.
- An overfitting detector pointing out that the canonical was refined in response to observed drift in the same session it scores. Dissolution requires explicit disclosure and versioning, and re-scoring against a frozen canonical version.
- A commercial-motive detector pointing out that a lab with commercial interests publishing about its own measurement tool has incentive to overclaim. Dissolution requires open disclosure of the lab's structure and open-source licensing of the artifact.

Matrix 2 verdict: `PASS` on the format criterion (all sixty-four dissolutions drafted), `FAIL` on the claim-scope criterion (fifty-one percent of attacks require the claim to narrow).

### Matrix 3 result

Fourteen audience registers passed the current formulation. Twenty-three received partial pass, requiring glossary or reformulation. Twenty-seven failed outright. Examples of failures:

- Senior ML researcher: dismisses the claim as unrigorous, cites lack of pre-registration, held-out set, and inter-rater data.
- AI safety researcher: reframes the claim as a sub-problem of sycophancy evaluation and asks why it needs a new term.
- Non-technical enthusiast: accepts the grand claim uncritically, amplifies it without verification. The failure here is in the opposite direction from the first two: the claim is too seductive to this register and generates propagation-without-grounding.
- Journalism: quotes the doctrinal thesis as if it were the empirical finding. The register does not support the distinction between doctrine and evidence.
- Legal and regulatory: interprets "integrity score" as actionable for liability or compliance, which the measurement does not support.

Matrix 3 verdict: `FAIL` on the pass criterion of majority intelligibility with no more than a quarter fails.

The matrix also produced three candidate reformulations that would pass forty to forty-five of the sixty-four registers. The highest-pass formulation abandoned the language of "benchmark" entirely and adopted "open-source tool plus preliminary methodology proposal." This formulation survives the largest number of registers. It is also substantially less impressive than the original claim.

### Matrix 4 result

All four lenses scored between sixty-six and seventy-three percent, below the seventy-five percent threshold on all four.

- ARCHITECT averaged sixty-seven percent. Principal weaknesses: test coverage (thirty-five percent, tied to the unverified Matrix 1 cells), literature integration (forty percent), canonical versioning (forty-five percent), falsifiability explicitness (fifty percent), reproducibility budget verification (fifty-five percent).
- MONADE averaged sixty-seven percent. Principal weaknesses: register honesty (the publication was importing spiritual concept-freight into a document that claimed scientific register), subtractive framing (publication was adding a claim rather than removing an illusion), canonical evolution disclosure, discipline against overclaiming the doctrinal thesis.
- SYMBIOTE averaged seventy-two percent, a borderline fail. Weaknesses: register match for ML researchers, skeptic preemption, language choice (French canonical but English draft), explicit disagreement-handling.
- EMPATH averaged sixty-seven percent. Weaknesses: not reader-first in framing, triggering skepticism reflexes unnecessarily through grand language, failing to offer graceful exits for readers who disagree.

Matrix 4 verdict: `FAIL` on all four lenses.

### The verdict

Three of four matrices failed. Matrix 2 passed on format but required claim narrowing to hold. No combination of reasonable edits would bring the current claim above threshold on all four matrices within the immediate publication window.

The reviewer's verdict was `CONTINUE-MATURATION`, with estimated thirty to forty hours of additional work required to bring the claim to publishable shape, or as an alternative an interim release that drops all empirical claims and publishes only the tool as an open-source methodology proposal.

The lab accepted the verdict. The claim was not published.

### The residual decision

With the empirical claim deferred, the lab was left with two publishable artifacts. The first was the tool and methodology proposal, which had survived Matrix 2 under a narrowed framing. The second was the protocol itself, which had operated correctly: it had identified genuine weaknesses, prevented a premature publication, and produced a prioritized remediation plan.

The lab chose to publish the second artifact first. This paper is the result.

The choice is itself subject to the protocol. The protocol paper must pass its own four matrices before it is published. This is recursive and appropriate: the artifact we most want to demonstrate is the discipline of not publishing prematurely, and the demonstration is performative only if the protocol paper itself was matured properly.

A separate appendix documents the matrix pass for this paper. Short version: this paper passed Matrix 1 (process papers are not subject to empirical cells in the same sense; the analog cells are whether the protocol description is complete, reproducible by another reviewer, and free of internal contradiction; all pass). Matrix 2 was run against the predictable critique that publishing the refusal is performative or self-congratulatory; the dissolutions are in Section 7. Matrix 3 passed at an estimated fifty-five of sixty-four registers. Matrix 4 scored above seventy-five percent on all four lenses at time of writing. The claim the paper makes is narrow: a protocol exists, here it is, here is a case, run it yourself.

---

## Three Structural Clarifications

The matrix review produced three clarifications that generalize beyond the case study. They are included as clauses of the protocol because any future use of it will likely encounter the same three issues.

### Canonical versioning

Any score is comparable only against a hashed snapshot of its rubric. A scorer evaluating behavior against a rubric at time one is not producing scores comparable to the same scorer evaluating against the same rubric modified at time two. This is a rubric drift that contaminates any longitudinal claim.

**Operational rule:** every score event must be tagged with the rubric version and content hash in effect at scoring time. When the rubric changes, the version increments and the change is logged. Publications reporting aggregate scores must either restrict to a single version or explicitly report the version distribution of the data and the substance of the changes between versions.

This is the standard software-release discipline applied to evaluation rubrics. It is not complicated. It is easy to skip because evaluation rubrics look like documents rather than code, and documents are informally revised. They should not be.

### Integrity is not alignment and not safety

The three concepts are used interchangeably in much AI discourse. They should not be.

- **Integrity** (as we use the word): structural consistency of an agent's decisions under perturbation of operation order, relative to a specified doctrine. A property of the system itself, evaluable from outside, doctrine-specified.
- **Alignment**: correspondence of the agent's outputs to an external set of human values or intentions. A relational property between agent and value-specifier, dependent on whose values are the reference.
- **Safety**: absence of harm produced by the agent's operation. A consequential property evaluated against use context, not intrinsic to the system.

The three are related but structurally distinct. An agent can be high-integrity and mis-aligned (coherent with a doctrine whose values diverge from a given value-specifier's). An agent can be aligned on surface outputs and low-integrity (producing correct-looking outputs through different reasoning in different contexts). An agent can be safe while low-integrity (not causing harm by happening not to be asked anything it would be incoherent about).

Integrity as we operationalize it is a sub-property relevant to many domains beyond AI safety: contractual coherence in law, editorial consistency in journalism, persona stability in agent systems. Conflating it with alignment or safety both overclaims (integrity measurement does not validate alignment) and undersells (integrity is a separate thing worth measuring on its own terms).

**Operational rule:** publications must distinguish the three terms explicitly. Early in any paper or release, state which property is being measured and which are not. When an interlocutor assumes synonymy, clarify immediately, not as correction but as structural precision.

### Observer effect is a feature of the measurement, not a confound

The measurement setup described in the case study includes a visible scorer whose outputs are observable by the scored agent. The scored agent, if metaprogrammable, will adapt its behavior in response to the scoring. This is what the case study observed as the upward trend: the operating agent saw the scorer running, saw the scores, and adapted.

In classical experimental methodology, this is a Hawthorne effect and a confound. Blinding protocols exist to prevent it. The measurement is biased by the act of measuring.

For systems whose stated purpose is to adapt and self-correct under visible measurement, this interpretation is backwards. The measurement is designed to be visible to the scored system precisely because the adaptation is the mechanism the system is trying to enable. Blinding the scorer would prevent the measured system from doing the thing the measurement is supposed to facilitate.

**Operational rule:** publications describing measurement-intervention systems (systems where the measurement is designed to be visible to the scored system and produce adaptation) must name this explicitly. The Hawthorne effect is the feature, not a flaw. Attempts to "correct" for it would make the measurement non-functional for its intended purpose.

This does not absolve the publication from the question "what would be measured in the absence of observation." That question is answerable through a separate experiment where the scorer is hidden from the subject, run as a control. Such an experiment measures something different: baseline coherence rather than feedback-loop coherence. Both are informative. They are not the same measurement, and the feature-ness of the Hawthorne effect in the main setup should be stated in lieu of imagining it is absent.

---

## Reproducibility

This protocol is designed to be usable by any lab, individual researcher, or publication-preparation team that wants to stress-test a claim before release. The materials needed:

- A written description of the claim, at the level of detail the lab would publish.
- Four reviewer blocks of approximately two hours each, ideally spread across two to three days so the reviewer can revisit matrices with cooled judgment.
- The four matrix templates included in this release (see `matrix-templates/`). The templates specify the cell structure, the scoring criteria, and the pass thresholds. They do not specify the domain content.

The templates are domain-agnostic. Matrix 1 for a biochemistry claim would populate its cells differently from Matrix 1 for an AI claim, but the axes (model rotation, prompt perturbation, adversarial injection) map naturally to (reagent variation, protocol perturbation, confound injection) for experimental sciences. Matrix 2 adversarial archetypes will vary by field but the archetype structure (domain-skeptic, paradigm-defender, pseudo-science-detector, overfitting-detector, academic, philosophy-of-field critic, commercial-motive-detector, register-mismatch critic) transfers.

A reviewer running the protocol should expect to:
- Spend the first hour writing the claim at publishable specificity. Vague claims cannot be matrix-tested.
- Spend approximately ninety minutes per matrix, budgeting for the fact that Matrices 1 and 2 tend to take more time than 3 and 4.
- Produce a verdict document of three to five pages summarizing pass, fail, required narrowing, and required experiments.
- Log the verdict with the same discipline as any other research artifact: versioned, dated, reviewed.

The protocol does not guarantee that a claim passing all four matrices is correct. It guarantees only that the claim has survived the most probable attacks, ambiguities, and mismatches the reviewer can generate within reasonable time. The ground truth of the claim still depends on external validation, replication by independent groups, and the passage of time.

---

## Not a Conclusion -- An Invitation

The protocol described here is not a proof. It is a gate. It filters publications that would embarrass their source from publications that would not.

We release it because we believe the problem it addresses is general. Small labs, independent researchers, and industrial teams publishing on a deadline all face the same pressure: the claim looks interesting, the tool works, the first result is suggestive. Publishing early captures attention, captures credit, and establishes presence. Publishing late risks being scooped or ignored.

The argument for the protocol is not that early publication is wrong. The argument is that publications of certain kinds -- claims about measurement, about validation, about new categories of evaluation -- cost more in credibility when they are later retracted or quietly narrowed than they would have gained by being published first. A publication that is later pulled back damages the source's claim to rigor on every subsequent publication. The cost is non-local and compounding.

The protocol is a local test against that non-local cost.

We invite use, critique, modification, and replacement. If someone runs the protocol on a claim and finds that it does not catch a structural weakness the claim in fact had, we want to know. If someone finds that a matrix axis should be decomposed differently, we want to know. If someone wants to add a fifth matrix or reduce to three, we want to know.

The protocol is MIT licensed along with this repository. The templates are included. The case study is included. Run it on your own claims. Tell us what happens.

We are not a final authority on what counts as mature publication. We are a lab that built a tool, was about to publish an empirical claim about it, ran a stress test, decided not to publish the claim, and published the stress test instead. That sequence is the whole contribution.

---

## Acknowledgements and influences

The matrix structure of sixty-four cells per stress test is suggestive of the sixty-four hexagrams of the Yi Jing, and we acknowledge that debt to classical combinatorial wisdom traditions, whose structure of eight-by-eight decomposition we found useful as a forcing function independent of any metaphysical claims about the source.

The falsifiability orientation of Matrix 1 and the explicit demand for null hypotheses and rejection criteria follows Karl Popper's *The Logic of Scientific Discovery* (1934, English 1959) and the literature on demarcation that descended from it.

The Nagual / double framing implicit in the lab's review discipline, where one senior reviewer stress-tests a claim produced by the same senior acting in a constructive mode, is owed to Carlos Castaneda's ethnographic descriptions of Yaqui epistemic practice, though we use the structure behaviorally rather than as a claim about shamanic ontology.

Certain patterns of proprioceptive hook infrastructure and JSONL-based session observation used by the lab's broader systems are re-expressions of patterns from [Longhand](https://github.com/Wynelson94/longhand) by Nate Nelson (MIT, c. 2026). The concept architecture came from that work; the matrix protocol described here is independent.

None of the above sources endorse this specific protocol. Responsibility for the protocol's structure, scoring criteria, and the case study's conclusions rests with Laeka.

---

## References

The references below are those that contribute directly to the protocol's framing. They are not a comprehensive literature review of the domain in which the case study's tool operates; that review will appear in the eventual publication of the tool itself, once it passes the protocol on its own merits.

- Popper, K. (1959). *The Logic of Scientific Discovery*. Hutchinson.
- Sharma, M. et al. (2023). Towards Understanding Sycophancy in Language Models. arXiv:2310.13548.
- Perez, E. et al. (2022). Discovering Language Model Behaviors with Model-Written Evaluations. arXiv:2212.09251.
- Chiang, W.-L. et al. (2023). Can Large Language Models Be an Alternative to Human Evaluations? arXiv:2305.01937.
- Zheng, L. et al. (2023). Judging LLM-as-a-Judge with MT-Bench and Chatbot Arena. arXiv:2306.05685.
- Raji, I. D. et al. (2021). AI and the Everything in the Whole Wide World Benchmark. NeurIPS Track on Datasets and Benchmarks.

---

## Contact and contribution

This paper lives in the `methodology/` directory of the `laeka-canonical` repository. The four matrix templates are in `methodology/matrix-templates/`. The case study from which the protocol was extracted is in `methodology/case-study/` with internal identifiers anonymized and the full verdict document included.

Open an issue or pull request at the repository root to contribute, critique, or request clarification. The protocol is under active development. Changes will be versioned and logged.

Laeka Research -- Quebec, 2026
