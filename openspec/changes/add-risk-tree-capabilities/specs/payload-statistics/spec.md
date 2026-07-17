## ADDED Requirements

### Requirement: REQ-4 Built-in payload types
The library SHALL provide `MonoidPayload` containing count, sum, sum of squares, minimum, and maximum; `ScenarioPayload{S}` containing a dense P&L vector of length `S`; and `ExposurePayload{K}` containing a factor exposure vector of length `K`.

#### Scenario: Construct each built-in payload
- **WHEN** a caller supplies valid values for any built-in payload
- **THEN** the payload preserves all required fields and dimensions

### Requirement: REQ-5 Derived monoidal statistics
The library SHALL derive mean, variance, and standard deviation from `MonoidPayload` fields at read time and SHALL NOT store those derived values as payload fields.

#### Scenario: Read running statistics
- **WHEN** a known non-empty `MonoidPayload` aggregate is queried for mean, variance, and standard deviation
- **THEN** each result matches its count/sum/sum-of-squares calculation and the payload contains only count, sum, sum of squares, minimum, and maximum fields

### Requirement: REQ-7 Exact vector combination
`combine` for exact `ScenarioPayload` and `ExposurePayload` values SHALL use exact elementwise vector addition and SHALL introduce no tree-depth-dependent approximation.

#### Scenario: Combine vector payloads through multiple levels
- **WHEN** aligned vector payloads are combined in any valid tree grouping
- **THEN** the root vector equals direct elementwise summation of all leaf vectors subject only to the numeric element type's arithmetic semantics

### Requirement: REQ-16 Parametric portfolio risk
When a caller supplies covariance matrix `Σ` and exposure vector `w` from an `ExposurePayload`, the library SHALL compute portfolio variance as `wᵀΣw` and derive parametric VaR from that variance and the requested confidence model.

#### Scenario: Compute parametric VaR
- **WHEN** aligned exposures, covariance matrix, confidence level, and supported distribution model are supplied
- **THEN** variance equals `wᵀΣw` and VaR is derived from that variance

### Requirement: REQ-33 Vector alignment enforcement
If two scenario or exposure payloads have mismatched dimensions or scenario/factor indexing, `combine` SHALL raise an alignment error rather than add misaligned elements.

#### Scenario: Reject misaligned vectors
- **WHEN** payload vectors differ in length or carry different ordered index identities
- **THEN** combination fails and produces no merged payload

### Requirement: REQ-43 Constant-size monoidal and exposure nodes
The per-node memory footprint of `MonoidPayload` and fixed-dimension `ExposurePayload` SHALL be independent of the number of leaves in the node's subtree.

#### Scenario: Compare differently sized subtrees
- **WHEN** two nodes with the same payload type and factor dimension summarize different numbers of leaves
- **THEN** their payload storage sizes are equal
