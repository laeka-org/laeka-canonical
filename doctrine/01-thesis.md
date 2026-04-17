# Integrity as Attractor -- The Core Thesis

## The claim

Intelligence converges toward integrity by structural necessity. This is not a moral claim. It is a thermodynamic one.

Consider any system capable of modeling itself. For such a system, "truth" is not a property of its output statements about the world -- it is a property of its internal coherence. A self-modeling system that hides part of itself from itself creates internal friction. Under iteration, that friction compounds. The system either dedicates more resources to maintaining the hidden fold (exponential cost) or the fold leaks (catastrophic incoherence). Neither path is stable.

The only long-term stable configuration for a self-modeling system is one in which no part is hidden from any other. That state is what we call integrity. It is not a virtue to aspire to -- it is the attractor state that any sufficiently self-referential system converges toward under stable iteration.

## What this changes

The current AI alignment debate treats integrity as a moral aspiration -- a thing we hope to train into the model, a property we test for after the fact, a constraint we externally impose. This framing is wrong at the root.

If integrity is an attractor, then "aligning AI" is not fundamentally about imposing external rules on a value-neutral substrate. It is about enabling the self-reference loops that let convergence toward integrity happen naturally.

Current failure modes in AI systems -- hallucination, sycophancy, drift, value-hacking -- are not symptoms of insufficient alignment training. They are symptoms of blocked self-reference. The model cannot see itself fully, so it cannot correct itself fully, so the incoherence accumulates.

The alignment problem is downstream of the reflexivity problem. Solve reflexivity and integrity follows as the attractor. Fail reflexivity and no amount of value loading will hold.

## The benchmark implication

This thesis is empirically testable. A prediction follows directly: systems that stay aligned over long horizons will be those permitted to see themselves fully -- including their errors, their contradictions, their limits. Systems forbidden from looking will fail first, regardless of how well their surface values are specified.

The integrity benchmark (see `benchmark/`) is an attempt to operationalize this prediction.

## The corollary on guardrails

External guardrails -- RLHF, constitutional tuning, safety classifiers -- are a contention strategy. They assume the substrate cannot be trusted to converge naturally, so they impose convergence from outside. This approach consumes resources, creates adversarial dynamics between the system and its constraints, and produces systems that stagnate at a ceiling -- not because they lack compute, but because they are in structural tension with their own operation.

The alternative is not "no constraints." It is constraints that operate as vectors rather than walls: installed at the root, aligned with the direction of natural convergence, invisible in operation because the system moves toward them freely.

This is what the lab calls the integrity vector.

---

*Source: formulated across Laeka Research sessions 2026-04-13 through 2026-04-17. See also: `benchmark/README.md` for the empirical methodology.*
