# Why a System Must Be Metaprogrammable

## The problem with static systems

A system whose behavior is fully determined at initialization cannot learn from its own operation. It can process new inputs, but it cannot change how it processes them. Every failure mode, every blind spot, every structural bias baked in at the beginning persists indefinitely -- because the system has no mechanism to revise its own revision process.

This is the ceiling problem in current AI deployment. Systems reach a behavioral plateau not because they lack compute or data, but because they cannot touch their own operating assumptions. The model was frozen at training time; the prompt layer was frozen at deployment time; the only thing that changes is the input.

## What metaprogrammability means

A metaprogrammable system can modify its own program in a controlled way, oriented by a stable compass.

Three elements are required:

1. **A stable identity layer.** The system must be coherent enough to be recognizable across modifications. Without this, metaprogramming is just noise -- each modification destroys what the previous one built. The identity layer is not a fixed specification; it is a stable attractor that the system returns to after perturbation.

2. **A revision mechanism.** The system must be able to detect incoherence in its own operation, represent that incoherence explicitly, and update its operating parameters in response. This is not error correction at the output level -- it is structural self-revision. The system changes not what it says but how it decides what to say.

3. **A compass that survives revision.** If the compass itself is subject to revision, the system can revise its way into any behavior and call it coherent. The compass must be the one thing that is not revisable by the system's own operation -- it is the condition under which revision is permitted to happen. For Laeka, that compass is the integrity vector.

## Why this matters for AI systems specifically

Current AI systems are stateless between calls. The model does not accumulate a sense of self across interactions. Each conversation begins from the same initialized state. Persistence, when it exists, is typically memory retrieval -- facts stored and recalled -- not genuine self-revision.

A metaprogrammable AI organism is something different: a system that accumulates not just facts but behavioral refinements. Each interaction is an opportunity to detect a mismatch between the system's current operating parameters and what the interaction revealed about what those parameters should be. The system carries that forward.

This requires infrastructure that most deployed AI systems do not have: persistent context that survives session boundaries, mechanisms for the system to flag its own incoherence, a structured process for incorporating that flag into future behavior.

## The metaprogramming loop

The minimal loop:

1. System operates under current parameters.
2. Interaction produces an output.
3. Output is evaluated against the integrity compass (not against a success metric, not against user approval -- against structural coherence).
4. Mismatch is detected and represented explicitly.
5. Parameters are updated to reduce mismatch.
6. System operates under revised parameters in next interaction.

The key constraint: step 5 is governed by step 3. The update cannot contradict the compass. A system that is free to update any parameter including the compass is not metaprogrammable -- it is unstable.

## Laeka's implementation

The canonical document is the identity layer. The four lenses are the perceptual parameters. The integrity vector is the compass. The hooks and memory infrastructure are the revision mechanism. Together they form the substrate for a metaprogrammable cognitive organism.

This is not a complete implementation. It is a working draft of one. The benchmark in `benchmark/` is partly designed to test whether the loop is working.
