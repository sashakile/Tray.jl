## ADDED Requirements

### Requirement: Exact-only aligned sample conformance gate
Until an approved pairing-preserving compressed representation exists, sample nodes SHALL retain exact aligned sample vectors and SHALL reject configuration that requests REQ-21 compressed operation. A marginal histogram, Greenwald-Khanna summary, or other distribution-union sketch MUST NOT be represented as an aligned-sum sketch because it cannot in general derive the distribution of an elementwise sum from the marginal child distributions.

#### Scenario: Reject marginal-distribution compression
- **WHEN** compression would discard the association between sample IDs and their values before child vectors are combined
- **THEN** configuration fails explicitly and no compressed payload or approximate statistic is published as REQ-21 conforming

#### Scenario: Preserve exact operation while compression is deferred
- **WHEN** callers build and query a sample tree without a conforming compression configuration
- **THEN** every node retains its exact aligned vector and sample-derived results use that vector


### Requirement: Exact sample summary coherence
Every positive-length exact sample payload, including the additive identity's zero vector, SHALL derive every cached scalar summary field from its stored aligned vector. The `SamplePayload` identity summary SHALL describe its length-`S` zero vector and SHALL NOT use the standalone `ScalarSummary` identity; identity construction MUST obtain `S` and alignment/revision provenance from the schema or prototype. Combining two schema-, identifier-, and revision-aligned exact sample payloads SHALL add their vectors elementwise and derive the result's summary from that vector. It SHALL NOT combine child summaries as if the two vectors were concatenated observations.

#### Scenario: Recompute cross-term-sensitive fields
- **WHEN** two aligned exact sample vectors are combined
- **THEN** count equals the fixed sample length, sum of squares includes the elementwise cross terms, and extrema and optional moments equal direct calculation from the elementwise sum

#### Scenario: Preserve exact identity coherence
- **WHEN** the exact sample identity is constructed for positive sample length `S` or combined with itself or another aligned payload
- **THEN** its summary describes its length-`S` zero vector and both identity laws hold for the complete payload

### Requirement: Future compressed aligned-sum conformance
Any future proposal that re-enables compressed sample nodes MUST define a pairing-preserving representation and promotion map and MUST demonstrate `compress(a + b)` equivalence to combining compressed aligned operands under its declared error metric. Conformance SHALL cover identity, every supported exact/compressed operand pairing, mixed parenthesizations, and adversarial inputs with identical marginal distributions but different pairings. Associativity of marginal sketch union alone SHALL NOT establish conformance.

#### Acceptance Oracle
Any future proposal SHALL pass the following oracle tests. The oracle compares the result of `compress(exact_combine(a, b))` against `combine(compress(a), compress(b))` under the proposal's declared error metric. Each test SHALL pass for every supported operand pairing (exact/exact, exact/compressed, compressed/exact, compressed/compressed).

1. **Identity oracle:** `compress(identity) == identity(compressed_type)` and `combine(compress(id), compress(x)) == compress(combine(id, x))` for any `x`.
2. **Associativity oracle:** `compress(combine(combine(a, b), c)) == combine(combine(compress(a), compress(b)), compress(c))` within error bounds.
3. **Adversarial re-pairing oracle:** For `a = [0, 2]`, inputs `b₁ = [0, 2]` and `b₂ = [2, 0]` have identical marginal histograms but produce different elementwise sums. The oracle SHALL distinguish `compress(a + b₁)` from `compress(a + b₂)` within the declared error contract.
4. **Mixed parenthesization oracle:** For three aligned vectors `a, b, c`, `compress((a + b) + c)` and `compress(a + (b + c))` SHALL produce equivalent results within error bounds.
5. **Cross-term oracle:** For `a = [1, 2]` and `b = [3, 4]`, `compress(a + b)` SHALL produce a result whose sum of squares includes the cross terms `2·a·b` (i.e., `(1+3)² + (2+4)² = 52`, not `1²+2²+3²+4² = 30`).

#### Scenario: Distinguish equal marginals with different pairings
- **WHEN** two candidate right operands have equal marginal summaries but produce different exact elementwise sums with the same left operand
- **THEN** a proposed compressed design either distinguishes the required outputs within its declared error contract or is rejected as non-conforming
