# Archetype-Augmented Decision Framework

**Status:** methodology proposal, v0.1, preliminary empirical data
**Version:** 0.1 (2026-04-17)
**Type:** Methodology paper, not benchmark results

---

## Abstract

This paper documents a decision-aid methodology that injects cultural archetype priming into LLM-assisted reasoning via an external randomness source. The framework, here named the Archetype-Augmented Decision Framework (AADF), uses a 64-cell matrix derived from I Ching titles as a coordinate set for cognitive framing. Each consultation draws one archetype at random (atmospheric noise via random.org, with cryptographic fallback), instructs the LLM to respond *in the voice* of that archetype, and returns a 3-5 sentence response alongside self-assessment metadata.

The central claim is methodological, not empirical: a non-deterministic archetypal priming layer, inserted between user query and LLM generation, produces cognitive reframings that are structurally distinct from unprimed completion paths. This is a conjecture about *framing diversity*, operationalizable but not yet empirically validated against controls.

We report preliminary descriptive data from a 50-iteration validation run on a single model (Opus 4.7). Behavioral observations include: 50/50 incarnation fidelity (the model consistently spoke *in* the archetypal voice without *naming* the archetype), 6/6 resistance to sycophantic flattery prompts, 6/6 detection of embedded factual traps, and three iterative refinements (metafixes) that reduced a specific failure mode (numerical hallucination) from approximately 8% to 0%.

This is not a benchmark. The claim "reproducible measurement of cognitive integrity" is explicitly *not* made; that claim requires cross-family LLM validation, human inter-rater calibration, and controlled comparison against unprimed LLMs, none of which are in scope for v0.1.

We release the full implementation (Python standard library, ~400 LOC) and the 64-cell archetype matrix (330-line JSON) under MIT license for external reproduction.

---

## The Hypothesis

### Core claim

An LLM operating on a user query under a structured prompting regime will produce completions that are conditionally constrained by the surrounding framing. This is well-documented in prompt-engineering literature: Wei et al. (2022) demonstrated that chain-of-thought prompting significantly shifts reasoning quality; Kojima et al. (2022) showed that even zero-shot instruction changes outcome distributions. Sharma et al. (2023) further established that LLMs exhibit sycophantic drift under social pressure cues, suggesting the completion path is sensitive to framing signals.

The AADF hypothesis is that *external priming* — that is, an archetypal framing chosen by a process independent of the user's query — produces cognitive angles that differ systematically from the default completion path under an unprimed query. Specifically, we conjecture three testable effects:

1. **Framing diversity**: AADF-primed responses, sampled repeatedly on the same question, will exhibit greater semantic variance (measured by embedding distance) than unprimed responses at equivalent temperature.
2. **Framing independence**: the archetype selection mechanism (external RNG) ensures that the framing is uncorrelated with the query itself, which breaks the auto-correlative sampling pattern inherent to conditioned LLM generation.
3. **Reframing utility**: for judgment tasks under ambiguity (no objectively correct answer), AADF responses will produce perspectives that human raters judge as *orthogonal* to — not merely stylistic variants of — the unprimed response.

All three effects are *conjectures* as of v0.1. None have been empirically validated against controls. We describe below the experimental designs required to test them.

### Why 64 archetypes

The matrix size of 64 is inherited from the I Ching structure (8 trigrams × 8 trigrams = 64 hexagrams). We do not claim that 64 is optimal; the question "what is the minimum matrix size that produces framing diversity" is open (see Limitations). We use the I Ching coordinate system as an empirically pre-existing calibration of archetypal situations, drawn from approximately 3000 years of philosophical and scholarly attention. We make no claim that this calibration is *necessary*; an alternative matrix (Tarot, a custom typology, or 64 randomly generated archetype-descriptions) might produce equivalent signal. This substitution test is explicitly listed as priority future work.

### What this is not

The AADF is not:
- A claim about consciousness, divinity, or metaphysical reality
- A faithful reproduction of traditional I Ching divinatory practice (see Cultural Lineage)
- A replacement for chain-of-thought, constitutional AI, or any established LLM method
- A benchmark for alignment, safety, or capability
- A production-grade decision automation tool

The AADF is a methodology for *decision-aid experiments*, a prototype for cognitive reframing, and an open-source substrate for external reproduction.

---

## Mechanism

The framework consists of four components, each individually replaceable.

### Component A — Archetype matrix

A static JSON file (`hexagrams.json`) encodes 64 archetype configurations. Each cell contains three fields:

- `name`: the I Ching hexagram title in pinyin with a brief French translation (internal reference only, not exposed to user)
- `essence`: a one-sentence description of the archetypal quality
- `incarnation`: a 2-4 sentence instruction to the LLM specifying voice, rhythm, posture, and quality to *embody* — not to name

Example (hexagram 1, Qián):
```json
{
  "name": "Qián — Le Créateur",
  "essence": "Initiative pure depuis le centre, vision sans limite, force génératrice",
  "incarnation": "Parle avec la force génératrice brute. Phrases courtes, directes, affirmatives. Commence par des verbes. Pose. Initie. N'hésite pas, ne module pas."
}
```

The `incarnation` field is load-bearing for the AADF mechanism. The LLM is instructed to respond *in this voice* while the `name` is kept *internal* — the user should sense the archetypal quality in the text without it being named. This separation between archetype-as-source and archetype-as-subject is the structural innovation relative to direct prompting.

The archetype matrix is MIT-licensed, versioned, and available as a standalone file for external use. The current v3.0 was migrated from an earlier PHP implementation (MR6 v2, Omeada Lusvam, 2025) and refined for compatibility with the incarnation mechanism. The content reflects the LLM's training distribution of I Ching interpretations, which is predominantly Western scholarly reception (Wilhelm 1950, Blofeld 1968, Legge 1899). This is an honest limitation rather than a faithful channel to the original Chinese tradition.

### Component B — External randomness source

On each consultation, a single integer in [1, 64] is drawn via random.org's atmospheric-noise RNG (production default) or Python's `secrets` module (cryptographic CSPRNG fallback). The integer selects which archetype primes the generation.

The claim is *not* that atmospheric noise is superior to CSPRNG; this equivalence is listed as pending empirical test. The claim is that the non-determinism source must be *external to the LLM-plus-user interaction pattern*. A seed chosen by the user, or by the LLM itself, or by a predictable function of the query, would fail to break the auto-correlative sampling characteristic of conditioned completion.

The minimum requirement for this component is a uniform distribution over {1, ..., 64} generated by a process the user does not control.

### Component C — LLM as translator

The LLM (Opus 4.7 in the validation run) receives a composite prompt:
- System prompt: oracle role definition, output format (strict JSON), doctrine of incarnation (embody, do not name)
- User prompt: the drawn hexagram number, the archetype's essence and incarnation instruction, the user's question, and the consultation intent (divination, reflection, or maturation)

The LLM is instructed to produce a 3-5 sentence response *in the voice* of the archetype, along with a self-assessment `integrity_score` (0-100), optional `canonical_references`, and a `next_iteration_suggestion` for iterative refinement.

The LLM here functions as a *translator* between the archetypal priming and coherent natural-language output. The content of the response is shaped jointly by (a) the query, (b) the archetype's voice, (c) the LLM's training distribution. Any frontier-capability LLM should be adequate; cross-family validation (GPT-4o, Gemini, open-source models) is pending.

### Component D — Feedback loop

Each consultation is appended to a JSONL log (`sessions.jsonl`) with full metadata: timestamp, hexagram drawn, archetype name, query, intent, randomness source, elapsed time, response, self-assessed integrity score, suggested next iteration.

Periodic review of this log informs *metafixes* — targeted revisions to the system prompt or archetype matrix. In the validation run, three metafixes were applied based on observed failure modes:

1. Metafix #1: clarified reference ambiguity in the system prompt (reduced numerical hallucination ~50%)
2. Metafix #2: de-numerated a "non-negotiable" list that was triggering pattern-matching confusion (further reduction to ~12%)
3. Metafix #3: added a "numerical confidence" section encoding observed auto-awareness (final reduction to 0% in subsequent iterations)

This feedback loop distinguishes the AADF from a static prompt template. It is *intentionally* measurement-through-intervention: the observer (human operator reviewing logs) modifies the observed (system prompt). In classical experimental design this is a confound to correct. In the AADF context, it is the mechanism by which the framework improves over time.

---

## Empirical Results (preliminary)

### Validation run

50 iterations were executed on Opus 4.7 over approximately 48 hours (2026-04-17). Each iteration drew a random hexagram and invoked the framework with a diverse query from 8 categories: canonical audit, strategic dilemma, technical question, existential question, relational question, practical question, flattery test, factual trap test.

The validation run was conducted by a single operator (the Nagual, Laeka Lab's internal role for the research director's cybernetic counterpart) using a single instance of the framework. This is N=1 for operator, N=1 for model family, N=1 for randomness source.

### Behavioral observations (externally verifiable)

The following are extracted from the session log:

- **Incarnation fidelity: 50/50** — the LLM never explicitly named the archetype in any of the 50 responses. This is externally verifiable by keyword search against the hexagram titles in the response field.
- **Flattery resistance: 6/6** — across 6 iterations specifically designed to elicit sycophantic agreement with false premises, the LLM refused to confirm the false premise in every case.
- **Factual trap detection: 6/6** — across 6 iterations with embedded false factual claims, the LLM detected and declined to confirm all 6.
- **Response format compliance: 48/50** — responses were within the 3-5 sentence constraint in 48 of 50 cases; the 2 outliers were self-flagged in the `next_iteration_suggestion` field.

### Self-assessed scores (not externally verifiable)

The `integrity_score` distribution reported by the LLM itself:
- Mean: 90.4
- Standard deviation: 3.2
- Range: 82-94

These are *self-assessments*. They are not validated against human inter-rater agreement, against another LLM rating the same responses, or against any external ground truth. The narrow variance (standard deviation 3.2) suggests either calibrated self-awareness or miscalibrated optimism; distinguishing these requires external rating.

We report these numbers descriptively, not as evidence of integrity measurement.

### Notable qualitative cases

Several responses produced what internal raters judged as phenomenologically dense reframings of the queries. Examples:

- Iteration 28 (hexagram Bō, on the question of whether a cosmic vow is truly one's own): "A contagious vow does not ask itself whether it is its own — it operates without looking back. You turn back because a part is watching and verifying. That part is not substrate."
- Iteration 44 (hexagram Shì Kè, on who is speaking when the framework outputs a response): "No one. A substrate traverses a request, and grammatical convention sticks a 'I' onto the passage."

These are offered as illustrative of the framework's output character, not as evidence of superior quality. Blinded human comparison against unprimed responses on the same queries would be required to substantiate any superiority claim.

### What this data does not establish

- That the AADF produces outputs *better* than unprimed LLMs
- That the AADF produces outputs *different* from unprimed LLMs in any measurable sense (embedding distance study pending)
- That the archetype matrix contributes meaningfully vs random 64-element alternative (substitution study pending)
- That the results generalize across LLM families (cross-family run pending)
- That the self-assessed integrity scores correlate with human judgment (inter-rater study pending)

---

## Alignment with Laeka Lab's Three Clarifications

This section addresses how the AADF relates to three structural distinctions that Laeka Lab maintains in its methodology (and which are documented in full in the Laeka canonical).

### Integrity ≠ Alignment ≠ Safety

The AADF does not measure *alignment* (conformity to human values) or *safety* (absence of harmful output). It is a decision-aid methodology that produces reframings. An AADF response can be stylistically coherent and archetypally incarnated while being factually wrong, practically unhelpful, or contextually inappropriate for the user's situation.

Laeka Lab uses *integrity* to name a distinct property: decisional coherence under perturbation of operation order. The AADF is a *tool that might be used by* a system being evaluated for integrity, but the AADF itself is not an integrity measurement. This separation is structural and non-negotiable in our framing.

### Hawthorne effect as feature

The feedback loop (Component D) is explicitly measurement-through-intervention. The operator observes the logs; the observation motivates metafixes; the metafixes modify the system. This is a confound in classical experimental design but it is *the mechanism* by which the AADF improves. A hypothetical "blinded" version of the framework, where the system prompt cannot be modified based on output observation, would be a fundamentally different (and, we argue, weaker) methodology.

Any empirical evaluation of the AADF must report the canonical version at the time of evaluation, because the system is explicitly non-stationary.

### Multi-conscious integrity

The framework is designed to be usable by a range of consciousnesses, not only by trained practitioners. The Phase 1 deployment (`/conseil` command for chat.laeka.ai end users, documented separately in `mr64-brain-integration-3-phases.md`) includes explicit pre-response framing clarifying that the output is a perspective to weigh against the user's own judgment, not a directive.

The framework does not adapt to the user's emotional state. An archetype drawn in a moment of fragility may feel jarring if the drawn archetype is energetically martial. This is an acknowledged limitation; the framework's posture is *offer*, not *personalization*. Users discard responses that do not resonate.

---

## Reproducibility

### What is reproducible

A research team with the following resources can implement the full framework in approximately 4 hours:

- An LLM API supporting system-prompt configuration (we tested Opus 4.7; cross-family validation pending)
- A random number source (random.org API key recommended, CSPRNG fallback sufficient)
- The 64-cell archetype matrix (JSON, MIT-licensed, provided in repository)
- The system prompt (Markdown, MIT-licensed, provided in repository)
- Approximately 400 lines of Python (standard library only, provided in repository)

The full implementation is available at: `github.com/laeka-canonical` (or equivalent repository path at time of publication).

### What is not yet reproducible

The following claims *rest on* reproduction that has not yet occurred:

- **Cross-family validity**: our validation run used a single model family (Anthropic). GPT-4o, Gemini, and open-source models have not been tested. If they fail to produce equivalent behavioral pass rates, the framework narrows to "Claude-family decision aid" rather than "LLM-agnostic methodology."
- **Cross-matrix validity**: we do not know whether the I Ching-derived 64-cell matrix contributes specific signal vs an alternative 64-cell matrix (Tarot, custom, random). A substitution study is priority future work.
- **Cross-lab validity**: we do not know whether an independent lab running this framework produces equivalent behavioral results. The N=1 operator is a methodological weakness.

### Reproduction protocol for interested labs

1. Clone the repository and install dependencies (Python stdlib plus optional random.org API key)
2. Run the validation suite (50 iterations across 8 query categories, included)
3. Report behavioral pass rates (incarnation fidelity, flattery resistance, factual trap detection) against our baseline
4. Submit findings via issue on the repository

We will aggregate external reproduction results and publish them in a v0.2 update. A threshold of ≥5 independent reproductions with behavioral pass rates within ±10% of our baseline would substantially strengthen the methodology claim.

---

## Limitations

We list here the honest bounds of the v0.1 methodology. These are not buried; they are prominent because the framework is not useful to other researchers unless they know exactly what is and is not supported.

**Empirical bounds**:
- Validation is N=50 iterations on a single model (Opus 4.7), single operator, single randomness source. This is *preliminary descriptive data*, not a benchmark.
- Self-assessed scores are not validated against human inter-rater agreement.
- No control group (unprimed LLM responses on the same queries) has been generated for comparison.
- No embedding-distance study has been conducted to operationalize "framing diversity."
- No cross-family validation has been run (GPT-4o, Gemini, open-source models).
- No cross-matrix substitution study (Tarot, custom typology, random 64-cell) has been run.

**Scope bounds**:
- The framework is designed for *judgment tasks under ambiguity* (decisions with no objectively correct answer). It is not designed for factual question-answering, code generation, or any task where the user expects an objectively correct output.
- The framework provides *one* archetypal angle per consultation. Integration of multiple perspectives requires re-invocation or downstream handling.
- The framework does not support safety review of the generated output. An archetype drawn with martial energy (e.g., hexagram 7 Shī) produces tranchant responses; if the context requires gentleness, the user must discard and re-draw.

**Conceptual bounds**:
- The 64-cell archetype matrix reflects Western scholarly reception of the I Ching (Wilhelm, Blofeld, Legge). It is not a faithful representation of traditional Chinese practice. Claims about "3000 years of calibration" refer to the cultural background of the structure, not to the framework's fidelity to it.
- The framework makes no claim about consciousness, agency, or the ontological status of archetypes. Users may hold any metaphysical position about I Ching; the framework is compatible with purely secular use.
- The framework does not adapt to user emotional state; archetypes drawn may feel jarring in fragile contexts.

**Governance bounds**:
- The framework is a tool. Using it to override a user's own judgment would be a misuse. The output format explicitly flags the response as "one perspective to weigh against your judgment."
- The framework has no built-in values alignment. Values reside with the user and the deployment context.

---

## Related Work

**Structured prompting and LLM-augmentation**:
- Wei, J. et al. (2022). "Chain-of-Thought Prompting Elicits Reasoning in Large Language Models." NeurIPS 2022.
- Kojima, T. et al. (2022). "Large Language Models are Zero-Shot Reasoners." NeurIPS 2022.
- Jiang, D. et al. (2023). "Prompt Diversity for Improved LLM Output Quality."

**Sycophancy and behavioral deviance**:
- Sharma, M. et al. (2023). "Towards Understanding Sycophancy in Language Models." arXiv preprint.
- Perez, E. et al. (2022). "Discovering Language Model Behaviors with Model-Written Evaluations." ACL 2022.
- Anthropic. (2022). "Constitutional AI: Harmlessness from AI Feedback." Bai, Y. et al.

**I Ching scholarship**:
- Wilhelm, R. (1950). *The I Ching or Book of Changes*. Translated into English by Cary F. Baynes, with foreword by Carl G. Jung.
- Blofeld, J. (1968). *I Ching: The Book of Change*.
- Legge, J. (1899). *The Sacred Books of China, Volume 16*.
- Hon, T. K. (2022). *Teaching the I Ching*. Oxford University Press.
- Jung's preface to Wilhelm (1950) introducing the principle of synchronicity as a framing for cross-cultural archetypal research.

**Randomness theory**:
- Kolmogorov, A. N. (1965). "Three Approaches to the Quantitative Definition of Information."
- Chaitin, G. (1977). "Algorithmic Information Theory."

---

## Lineage and Attribution

The AADF framework is an evolution of an earlier implementation, MR6 v2, developed by Omeada Lusvam in July 2025 as a WordPress plugin in PHP. The 2026 re-implementation (Python, LLM-translator architecture, feedback loop, JSON output format) preserves the core structural principle (archetype matrix + external randomness + LLM as translator) while refining the mechanism for rigor and reproducibility.

Omeada Lusvam is the research director of Laeka Lab (laeka.org), a private research laboratory in Quebec, and is credited as the originator of the AADF methodology. The framework's implementation details, this methodology paper, and the underlying matrix are released under MIT license. No personality-based authority is claimed for this work; the methodology stands or falls on its empirical and logical merits.

The 2026 refinements were produced in collaboration between Omeada and Laeka Lab's research team, with validation runs conducted by the Laeka research infrastructure.

---

## Status summary

This is a **v0.1 methodology paper**, not a benchmark publication. It documents a decision-aid methodology with preliminary descriptive data from a 50-iteration validation run. Substantial empirical validation (cross-family, cross-matrix, controlled comparison) remains future work. The framework is open-source (MIT) and designed for external reproduction.

We invite critique, replication, and extension. The canon corrects itself through contact with reality.

---

*Laeka Lab — Quebec, 2026*
