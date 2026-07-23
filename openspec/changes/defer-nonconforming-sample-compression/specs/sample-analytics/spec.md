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
Combining two schema-, identifier-, and revision-aligned exact sample payloads SHALL add their vectors elementwise and SHALL derive every cached scalar summary field from the resulting vector. It SHALL NOT combine child summaries as if the two vectors were concatenated observations.

#### Scenario: Recompute cross-term-sensitive fields
- **WHEN** two aligned exact sample vectors are combined
- **THEN** count equals the fixed sample length, sum of squares includes the elementwise cross terms, and extrema and optional moments equal direct calculation from the elementwise sum

### Requirement: Future compressed aligned-sum conformance
Any future proposal that re-enables compressed sample nodes MUST define a pairing-preserving representation and promotion map and MUST demonstrate `compress(a + b)` equivalence to combining compressed aligned operands under its declared error metric. Conformance SHALL cover identity, every supported exact/compressed operand pairing, mixed parenthesizations, and adversarial inputs with identical marginal distributions but different pairings. Associativity of marginal sketch union alone SHALL NOT establish conformance.

#### Scenario: Distinguish equal marginals with different pairings
- **WHEN** two candidate right operands have equal marginal summaries but produce different exact elementwise sums with the same left operand
- **THEN** a proposed compressed design either distinguishes the required outputs within its declared error contract or is rejected as non-conforming
