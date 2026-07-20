## ADDED Requirements

### Requirement: REQ-4 Built-in summary types
The library SHALL provide convenience types `ScalarSummary` containing count, sum, sum of squares, minimum, and maximum; `SamplePayload{S}` containing a dense finite sample vector of positive length `S`; and `AlignedArrayPayload{K}` containing a finite aligned vector of positive length `K`. These types SHALL NOT restrict arbitrary user-defined payload types with lawful `combine` and `identity(schema)`. `ScalarSummary` construction MUST require integer `count ≥ 0`; count zero MUST be the unique schema identity (`sum=sumsq=0`, optional higher sums zero, `minimum=+Inf`, `maximum=-Inf`), and these sentinel extrema are the only permitted non-finite stored values. A nonzero count MUST have finite consistent sums/extrema; optional higher moments SHALL add mergeable sums of cubes and fourth powers.

#### Scenario: Construct each built-in payload
- **WHEN** a caller supplies valid values for any built-in payload
- **THEN** the payload preserves all required fields and dimensions

#### Scenario: Reject empty vector payloads
- **WHEN** a caller constructs a sample or aligned-array payload with zero elements
- **THEN** construction fails with a dimension error

#### Scenario: Construct a tail-moment monoidal payload
- **WHEN** moment-based tail estimation is enabled
- **THEN** the monoidal payload stores third- and fourth-power sums in addition to all baseline fields

#### Scenario: Reject non-finite or inconsistent observations
- **WHEN** a constructor receives NaN, infinity outside the canonical empty-identity extrema, negative count, a noncanonical empty payload, reversed extrema, or impossible sums
- **THEN** construction fails before the payload enters a tree

### Requirement: REQ-5 Derived scalar statistics
The library SHALL derive mean, population variance `sumsq / count - mean^2`, and population standard deviation from `ScalarSummary` fields at read time and SHALL NOT store those derived values as payload fields.

#### Scenario: Read running statistics
- **WHEN** a known non-empty `ScalarSummary` aggregate is queried for mean, variance, and standard deviation
- **THEN** each result matches its count/sum/sum-of-squares calculation and a baseline payload contains only count, sum, sum of squares, minimum, and maximum fields

#### Scenario: Reject undefined empty statistics
- **WHEN** mean, variance, or standard deviation is requested from the identity payload with count zero
- **THEN** the query fails with a domain error rather than returning a fabricated numeric value

### Requirement: REQ-7 Exact vector combination
`combine` for exact `SamplePayload` and `AlignedArrayPayload` values SHALL use elementwise vector addition in immutable identifier order, using the deterministic reduction and tolerance/rebuild policy of `REQ-3`, and SHALL introduce no additional tree-depth-dependent approximation.

#### Scenario: Combine vector payloads through multiple levels
- **WHEN** aligned vector payloads are combined in any valid tree grouping
- **THEN** the root vector equals direct elementwise summation of all leaf vectors subject only to the numeric element type's arithmetic semantics

### Requirement: REQ-16 Quadratic matrix projection
When a caller supplies a finite symmetric positive-semidefinite matrix `M` and aligned vector `w`, the library SHALL compute `wᵀMw`. `M` MUST be `K × K` with dimension identifiers ordered exactly as in `w`.

#### Scenario: Compute a quadratic projection
- **WHEN** an aligned vector and valid matrix are supplied
- **THEN** the result equals `wᵀMw`

#### Scenario: Reject invalid projection inputs
- **WHEN** the matrix is non-finite, non-square, asymmetric, non-positive-semidefinite, dimensionally mismatched, or label-misaligned
- **THEN** projection fails with an informative domain or alignment error

### Requirement: REQ-33 Vector alignment enforcement
Sample and aligned-array vectors SHALL carry immutable, ordered, unique identifiers. If two payloads have mismatched dimensions or non-identical identifier sequences, `combine` SHALL raise an alignment error rather than add misaligned elements.

#### Scenario: Reject misaligned vectors
- **WHEN** payload vectors differ in length or carry different ordered index identities
- **THEN** combination fails and produces no merged payload

#### Scenario: Reject invalid dimension identifiers
- **WHEN** a payload is constructed with missing or duplicate sample or dimension identifiers
- **THEN** construction fails with an alignment error

### Requirement: REQ-43 Constant-size scalar and aligned-array nodes
The per-node memory footprint of `ScalarSummary` and fixed-dimension `AlignedArrayPayload` SHALL be independent of the number of leaves in the node's subtree.

#### Scenario: Compare differently sized subtrees
- **WHEN** two nodes with the same payload type and aligned dimension summarize different numbers of leaves
- **THEN** their payload storage sizes are equal
