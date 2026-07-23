## Context
Tray aggregates aligned sample vectors by elementwise addition. A compressed state therefore needs enough joint information to approximate the distribution of `a + b` for equally indexed vectors `a` and `b`.

Marginal order-statistics summaries cannot do this. For `a = [0, 2]`, both `b₁ = [0, 2]` and `b₂ = [2, 0]` have identical histograms and identical GK summaries, but `a + b₁ = [0, 4]` and `a + b₂ = [2, 2]` have different distributions. No merge receiving only those marginal summaries can produce both required answers.

The current exact combine path has a related defect: it adds the sample vectors elementwise but combines their scalar summaries as if the observations were concatenated. The resulting count, extrema, and sum of squares do not describe the combined vector.

## Goals / Non-Goals
- Goals:
  - Prevent non-conforming compressed results from being represented as REQ-21 results.
  - Preserve a correct exact aligned-sample path.
  - Establish a decisive conformance oracle for future compression proposals.
- Non-Goals:
  - Select or implement a replacement compression algorithm.
  - Weaken aligned sample semantics into pooled-distribution semantics.
  - Claim mixed-representation coherence before a lawful compressed representation exists.

## Decisions

### Exact-only is the temporary conforming state
Until a pairing-preserving compressed representation is approved, sample aggregation remains exact. Configuration requesting REQ-21 compression fails explicitly rather than falling back to a marginal-distribution sketch.

### ADR-002 is superseded, not patched
Standard GK merge summarizes stream union. Renaming that operation or adding associativity tests cannot make it preserve aligned pairing. ADR-002 will be marked superseded by this change; a future ADR must define the representation, promotion map, error model, and source requirements together.

### Exact summaries are derived from the combined vector
Every positive-length exact payload, including the additive identity's zero vector, derives count, sum, sum of squares, extrema, and optional moments from its stored aligned vector. After elementwise addition, those fields are recomputed from the resulting vector. Combining the children's marginal summaries is not equivalent because it omits cross terms and doubles the observation count. Defining the identity summary from its zero vector also ensures `combine(identity, identity) == identity` after recomputation. This is specifically the `SamplePayload` identity summary, not the standalone `ScalarSummary` identity; identity construction obtains positive sample length `S` and alignment/revision provenance from the schema or prototype.

### Non-conforming compression leaves the public API
The current compressed types and query functions are removed from exports and normative documentation. Keeping pooled-distribution behavior under a separate public name is deferred to a future proposal so this correction has one unambiguous completion state.

### Future compression must pass an independent oracle
Conformance compares a candidate result with compression of the exact elementwise sum. Tests include equal marginal summaries with different pairings, all representation pairings supported by the candidate, identity, and mixed parenthesizations. Associativity without the aligned-sum oracle is insufficient.

## Alternatives Considered
- Keep histogram or GK union and add promotion tests: rejected because the operation is associative but computes the wrong population.
- Weaken REQ-21 to distribution union: rejected because it changes the meaning of sample aggregation and breaks aligned statistics.
- Source-backed recomputation on every merge: potentially lawful, but deferred because it changes complexity and availability assumptions.
- Coordinated sampling of stable sample IDs: promising, but requires a separate proposal for probabilistic error, seed/universe provenance, and tail-mean guarantees.

## Risks / Trade-offs
- Exact vectors retain `O(S)` storage per node; this is already permitted by REQ-44.
- Removing public compressed APIs can break callers, but preserving a silently incorrect result is worse. Release notes identify exact operation as the migration path.
- A future compression proposal may require revising REQ-22's error-composition model.

## Migration Plan
1. Mark ADR-002 superseded and amend the active REQ-21/task text to exact-only pending a replacement ADR.
2. Add failing regression tests for paired-sum counterexamples, exact summary correctness, and identity coherence.
3. Correct exact construction, identity, and combination.
4. Remove non-conforming compressed exports and normative documentation, with an explicit migration note to exact operation.
5. Re-enable compression only through a separately approved OpenSpec change and ADR.
