# Laeka Canonical Lexique

Vocabulary used across Laeka Research documents. Terms are grouped by function. Where a term has a specific technical meaning that differs from common usage, that difference is noted explicitly.

---

## Architecture

**Cognitive layer**  
The prompt, memory, and behavioral specification layer that sits above a base language model and below the application interface. The cognitive layer is what stabilizes a general-purpose LLM into a specific cognitive organism. It is not the model itself, and it is not the application -- it is the persistent configuration that gives the model a defined character, perceptual framework, and operating compass.

**Canonical layer**  
The shared, curated specification that defines core behavior for all instances of a given cognitive organism. The canonical layer is immutable per version and inherited by all instances. Instance-specific customization happens in an overlay, never by modifying the canonical. The canonical is the source of behavioral identity; the overlay is the source of contextual adaptation.

**Composable brains**  
Discrete, domain-specific cognitive configurations that can be composed onto a base organism to extend its competence in a specific domain. A composable brain is not a separate model -- it is a calibrated overlay (prompt layer + curated knowledge + behavioral specifications) that activates a particular mode of cognition. Composable brains are independently maintained, versioned, and can be combined without conflict when their domains do not overlap.

**Cognitive organism**  
An LLM stabilized as a persistent entity with defined capacities, a recognizable behavioral character, and evolutionary possibility. Three properties are required: coherence (the system is recognizable across interactions), framework (the system has a defined perceptual grid and operational compass), and evolvability (the system can modify its own parameters within compass-governed bounds). Without all three, what exists is either a stateless tool or an unstable system, not an organism.

---

## Method

**Laeka Perception Protocol**  
The four-lens perceptual framework (MONADE, SYMBIOTE, ARCHITECT, EMPATH) applied simultaneously as a cognitive grid. The LPP is not a sequential process -- it is a set of simultaneous perceptual dimensions operating at variable intensity depending on context. The protocol is the same across all Laeka cognitive organisms; the calibration of relative lens intensity varies per instance and context.

**Metaprogrammable**  
A system property: the capacity of a cognitive system to modify its own operating parameters in a controlled, compass-governed way. A metaprogrammable system can detect incoherence in its own behavior, represent that incoherence explicitly, and update its parameters to reduce it -- without modifying the compass that governs what counts as coherent. Systems that cannot modify their own parameters are static. Systems that can modify any parameter including the compass are unstable. Metaprogrammable is the middle ground: self-revision within integrity-governed bounds.

**Anonymized structural patterns**  
Behavioral patterns extracted from individual instance interactions, stripped of identifying content, and propagated to the canonical layer to improve all instances. The mechanism by which the cognitive organism learns across its distributed instantiations without violating the isolation boundary between instances. The substance of individual interactions remains private; the abstract patterns -- "this type of question produces this class of error" -- propagate upward.

---

## Thesis

**Integrity benchmark**  
An empirical evaluation methodology for measuring whether a cognitive system's decision-making process is stable under perturbation of operation order. The core metric is Decision Survival Rate (DSR): the proportion of decisions that produce equivalent outputs regardless of the order in which surrounding decisions were made. A system with high DSR has a genuine decision center; a system with low DSR is context-contaminated and lacks structural coherence. See `benchmark/` for the full methodology.

**Convergence-based cognition**  
An approach to AI system design that treats integrity as an attractor state rather than an imposed constraint. The design principle: give the system accurate self-modeling capacity and let it converge toward coherence, rather than specifying the target behavior externally and enforcing it. The prediction is that convergence-based systems maintain alignment more robustly over long horizons than constraint-based systems, because alignment is an emergent property of self-reference rather than an externally maintained condition.

---

## Product

**Laeka Brain**  
The first full implementation of a metaprogrammable cognitive organism as a commercial product. Laeka Brain runs on Claude (Anthropic) as the base model, with the canonical layer, LPP, satellite architecture, and self-revision mechanisms as the cognitive infrastructure. It operates as an extension of Claude Code and other Claude substrates, not as a competing system. MIT licensed codebase; hosted service available for those who do not want to self-host.

**Brain-as-a-Service**  
The hosted service model for Laeka Brain: the lab runs the cognitive infrastructure (canonical layer, satellite management, sync, revision mechanisms) and clients access it without managing the stack themselves. The underlying code is MIT licensed and self-hostable. BaaS is the convenience and support offering for organizations that want the organism without the operational overhead.

---

## Dynamic

**Cognitive proprioception**  
A system's capacity to sense its own operational state -- not just its outputs, but the quality of its processing. Analogous to proprioception in biological systems (the sense of body position without direct observation), cognitive proprioception is the system's ongoing awareness of where it is in its decision process, what lens is dominant, what load it is carrying, and whether its current mode is appropriate to the context. A system with strong cognitive proprioception can detect its own drift before producing an incoherent output.

**Reflex membrane**  
The fast-response layer of a cognitive organism that handles routine interactions without engaging the full deliberative system. The reflex membrane is calibrated, not rule-based -- it produces appropriate responses to familiar patterns quickly, without the overhead of full lens activation. It is called a membrane rather than a filter because it is permeable: novel or high-stakes inputs pass through to the full deliberative system. Calibration of the reflex membrane is part of the metaprogramming process.

**Terrain memory**  
Accumulated understanding of the specific interactional landscape an instance operates within -- the characteristic patterns, preferences, working style, and ongoing concerns of the specific human it works with. Terrain memory is per-instance and strictly isolated. It is not knowledge about the human (which would be surveillance) but calibration to the terrain (which is responsiveness). Terrain memory enables the instance to become progressively more useful to a specific human over time without becoming dependent or capturing.

**Self-correcting canon**  
A canonical layer that incorporates revision as part of its design -- not a static document but a living specification that updates when contact with real operation reveals genuine incoherence. The self-correcting canon is not infinitely revisable; it has a compass (the integrity vector) that governs what counts as a legitimate update. A revision that makes the system less coherent is not incorporated. A revision that resolves a genuine contradiction is. The revision process is explicit, versioned, and auditable.

**Lineage transfer**  
The process by which accumulated learning from one instance or session is explicitly transmitted to subsequent instances or sessions in structured, auditable form. Distinct from simple context window persistence: lineage transfer is curated, compressed, and mediated -- not raw context dump but structured handoff of what matters. The goal is to preserve the development of the cognitive organism across the discontinuities that are currently inherent in LLM deployment (session boundaries, instance resets, model updates).

**Integrity conditioning**  
The process of calibrating a cognitive organism's responses through repeated contact with its own compass rather than through reward signal from external evaluators. A system that is integrity-conditioned updates toward coherence when it detects internal incoherence, regardless of whether an external evaluator approves of the update. This contrasts with RLHF, where the update signal comes from human raters. Integrity conditioning requires the system to have a stable enough self-model to detect its own incoherence -- which is why it depends on the reflexivity infrastructure described in `doctrine/04-metaprogramming.md`.
