## Context
RiskTree is intended to aggregate portfolio data through independent hierarchies while preserving enough information to derive both mergeable statistics and non-additive risk measures. The source EARS document defines 44 requirements spanning core data structures, numerical behavior, optional storage modes, concurrency, and integrations.

## Goals / Non-Goals
- Goals:
  - Preserve every EARS requirement ID in an independently testable OpenSpec requirement.
  - Keep exact aggregation separate from optional approximation and integration features.
  - Define consistency and alignment guarantees at public boundaries.
- Non-Goals:
  - Select concrete sketch, memory-mapping, synchronization, or widget dependencies where the specifications define an implementation-neutral contract.
  - Define a materialized multidimensional cube.
  - Implement the proposed capabilities before approval.

## Decisions

### Capability boundaries
The requirements are split by user-visible responsibility rather than by EARS sentence form. Core tree mechanics, payload arithmetic, scenario risk, multidimensional composition, consistency/sharing, and dashboard integration can therefore evolve and be tested independently.

### Exactness and approximation
`ScenarioPayload` and `ExposurePayload` combination remains exact elementwise addition in exact mode. Sketch compression, Cornish-Fisher estimation, and fractional-depth scenario quantiles are explicitly approximate and must identify their approximation or error bound at the result boundary.

### Fractional level of detail
The root has depth zero and child depth increases by one. Fractional-depth queries are defined only for numeric scalar or fixed-length numeric-vector payload fields with identical schemas at both adjacent integer depths. General fractional-depth queries interpolate those fields before deriving statistics (`REQ-19`). Scenario quantiles are the explicit exception: when both fractional depth and scenario payloads are in use, matching points of the quantile functions are interpolated instead of raw scenarios (`REQ-38`).

### Statistical conventions
Scenario quantiles use a documented nearest-rank empirical convention. VaR and Expected Shortfall operate on losses, defined as negated P&L, while factor VaR uses a zero-mean Gaussian model. Component and marginal scenario VaR use covariance with the ancestor loss vector. These conventions remove implementation-dependent sign, tail, and distribution choices.

Moment-based Cornish-Fisher estimation requires skewness and excess kurtosis. When that optional mode is enabled, `MonoidPayload` therefore includes mergeable third- and fourth-power sums in addition to its baseline fields. The baseline payload remains unchanged when the mode is disabled.

### Approximation contract
Sketch compression uses subtree leaf count as its threshold metric. A sketch advertises an absolute rank-error bound `ε` in `[0, 1]`; approximate quantile, VaR, and Expected Shortfall results report that rank bound and do not imply a value-error bound. The concrete mergeable sketch algorithm remains an implementation choice.

### Versioned consistency
Concurrent root reads and range reads are specified separately without mandating locks, copy-on-write, CAS, or epochs. Root reads must not observe partially propagated updates (`REQ-23`), while ranges overlapping subtree reweighting must use a single version across the complete range (`REQ-40`).

### Independent axes
Groupby and time hierarchies share leaf-level source data but remain independently maintained. Intersection queries compose axis decompositions and must not require a precomputed cross-product cube.

### Alignment and historical updates
Scenario and factor dimensions carry immutable, ordered, unique identifiers. Combination requires exact identifier-sequence equality. A historical-window advancement identifies the leaves whose source series advanced; every changed leaf and ancestor is rebuilt, while a sibling is unaffected exactly when it has no changed descendant. A common-window shift can therefore affect the whole tree without implying that an unaffected sibling must exist.

### Shared-memory and dashboard contracts
Shared-memory mode is a live, potentially non-durable mapping that uses the same versioned binary layout as optional persistent mappings. The layout identifies format version, byte order, numeric types, dimensions, offsets, and snapshot epoch. Every language implementation declared compatible with a format version must pass the same conformance fixture.

Dashboard integration uses a serializable model with `get`, `set`, and `on("change:<key>")` behavior for `viewport_range`, `requested_depth`, `aggregate`, and `effective_depth`. This contract is transport-neutral and does not require a particular widget dependency.

## Risks / Trade-offs
- Exact scenario vectors consume memory proportional to the configured scenario count at every exact node. Optional sketches bound memory but make quantile results approximate.
- Dynamic insertion/removal and fixed-index canonical range decomposition can pull the implementation toward different tree layouts. The implementation must demonstrate both behaviors without weakening query guarantees.
- Cross-process structural sharing and browser model transport require stable serialization and synchronization boundaries; their contracts are fixed here while concrete dependencies remain deferred.
- The source complexity claim treats branching factor `b` as fixed and is interpreted as finding the decomposition in `O(log_b n)` plus the unavoidable cost of visiting or returning its canonical nodes.

## Migration Plan
This is a greenfield specification. Apply capabilities incrementally in dependency order: payload contracts, core tree, scenario risk, multidimensional composition, consistency/sharing, then optional integrations.
