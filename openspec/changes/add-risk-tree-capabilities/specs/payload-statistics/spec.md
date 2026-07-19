## ADDED Requirements

### Requirement: REQ-4 Built-in payload types
The library SHALL provide `MonoidPayload` containing count, sum, sum of squares, minimum, and maximum; `ScenarioPayload{S}` containing a dense P&L vector of positive length `S`; and `ExposurePayload{K}` containing a factor exposure vector of positive length `K`. All observations and vector elements MUST be finite. `MonoidPayload` construction MUST require integer `count ≥ 0`; count zero MUST be the unique schema identity (`sum=sumsq=0`, optional higher sums zero, `minimum=+Inf`, `maximum=-Inf`), and these two sentinel extrema are the only permitted non-finite stored values. A count greater than zero MUST have finite sums/extrema, `minimum ≤ maximum`, `sumsq ≥ sum²/count` within configured numerical tolerance, and higher sums consistent with enabled schema fields. When moment-based tail estimation is enabled, it SHALL additionally contain mergeable sums of cubes and fourth powers.

#### Scenario: Construct each built-in payload
- **WHEN** a caller supplies valid values for any built-in payload
- **THEN** the payload preserves all required fields and dimensions

#### Scenario: Reject empty vector payloads
- **WHEN** a caller constructs a scenario or exposure payload with zero elements
- **THEN** construction fails with a dimension error

#### Scenario: Construct a tail-moment monoidal payload
- **WHEN** moment-based tail estimation is enabled
- **THEN** the monoidal payload stores third- and fourth-power sums in addition to all baseline fields

#### Scenario: Reject non-finite or inconsistent observations
- **WHEN** a constructor receives NaN, infinity outside the canonical empty-identity extrema, negative count, a noncanonical empty payload, reversed extrema, or impossible sums
- **THEN** construction fails before the payload enters a tree

### Requirement: REQ-5 Derived monoidal statistics
The library SHALL derive mean, population variance `sumsq / count - mean^2`, and population standard deviation from `MonoidPayload` fields at read time and SHALL NOT store those derived values as payload fields.

#### Scenario: Read running statistics
- **WHEN** a known non-empty `MonoidPayload` aggregate is queried for mean, variance, and standard deviation
- **THEN** each result matches its count/sum/sum-of-squares calculation and a baseline payload contains only count, sum, sum of squares, minimum, and maximum fields

#### Scenario: Reject undefined empty statistics
- **WHEN** mean, variance, or standard deviation is requested from the identity payload with count zero
- **THEN** the query fails with a domain error rather than returning a fabricated numeric value

### Requirement: REQ-7 Exact vector combination
`combine` for exact `ScenarioPayload` and `ExposurePayload` values SHALL use elementwise vector addition in immutable identifier order, using the deterministic reduction and tolerance/rebuild policy of `REQ-3`, and SHALL introduce no additional tree-depth-dependent approximation.

#### Scenario: Combine vector payloads through multiple levels
- **WHEN** aligned vector payloads are combined in any valid tree grouping
- **THEN** the root vector equals direct elementwise summation of all leaf vectors subject only to the numeric element type's arithmetic semantics

### Requirement: REQ-16 Parametric portfolio risk
When a caller supplies covariance matrix `Σ` and exposure vector `w` from an `ExposurePayload`, the library SHALL compute portfolio variance as `wᵀΣw` and zero-mean Gaussian parametric VaR as `Φ⁻¹(c) * sqrt(wᵀΣw)` for confidence `c` in `(0.5, 1)`. `Σ` MUST be finite, symmetric, positive semidefinite, and `K × K` with factor identifiers ordered exactly as in `w`.

#### Scenario: Compute parametric VaR
- **WHEN** aligned exposures, a valid covariance matrix, and confidence `c` in `(0.5, 1)` are supplied
- **THEN** variance equals `wᵀΣw` and VaR equals `Φ⁻¹(c) * sqrt(wᵀΣw)`

#### Scenario: Reject invalid parametric inputs
- **WHEN** confidence is outside `(0.5, 1)` or the covariance matrix is non-finite, non-square, asymmetric, non-positive-semidefinite, dimensionally mismatched, or label-misaligned
- **THEN** parametric risk calculation fails with an informative domain or alignment error

### Requirement: REQ-33 Vector alignment enforcement
Scenario and factor vectors SHALL carry immutable, ordered, unique identifiers. If two scenario or exposure payloads have mismatched dimensions or non-identical identifier sequences, `combine` SHALL raise an alignment error rather than add misaligned elements.

#### Scenario: Reject misaligned vectors
- **WHEN** payload vectors differ in length or carry different ordered index identities
- **THEN** combination fails and produces no merged payload

#### Scenario: Reject invalid dimension identifiers
- **WHEN** a payload is constructed with missing or duplicate scenario or factor identifiers
- **THEN** construction fails with an alignment error

### Requirement: REQ-43 Constant-size monoidal and exposure nodes
The per-node memory footprint of `MonoidPayload` and fixed-dimension `ExposurePayload` SHALL be independent of the number of leaves in the node's subtree.

#### Scenario: Compare differently sized subtrees
- **WHEN** two nodes with the same payload type and factor dimension summarize different numbers of leaves
- **THEN** their payload storage sizes are equal
