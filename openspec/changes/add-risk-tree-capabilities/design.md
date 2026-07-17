## Context
RiskTree is intended to aggregate portfolio data through independent hierarchies while preserving enough information to derive both mergeable statistics and non-additive risk measures. The source EARS document defines 44 requirements spanning core data structures, numerical behavior, optional storage modes, concurrency, and integrations.

## Goals / Non-Goals
- Goals:
  - Preserve every EARS requirement ID in an independently testable OpenSpec requirement.
  - Keep exact aggregation separate from optional approximation and integration features.
  - Define consistency and alignment guarantees at public boundaries.
- Non-Goals:
  - Select concrete sketch, memory-mapping, synchronization, or widget dependencies during specification.
  - Define a materialized multidimensional cube.
  - Implement the proposed capabilities before approval.

## Decisions

### Capability boundaries
The requirements are split by user-visible responsibility rather than by EARS sentence form. Core tree mechanics, payload arithmetic, scenario risk, multidimensional composition, consistency/sharing, and dashboard integration can therefore evolve and be tested independently.

### Exactness and approximation
`ScenarioPayload` and `ExposurePayload` combination remains exact elementwise addition in exact mode. Sketch compression, Cornish-Fisher estimation, and fractional-depth scenario quantiles are explicitly approximate and must identify their approximation or error bound at the result boundary.

### Fractional level of detail
General fractional-depth queries interpolate payload fields before deriving statistics (`REQ-19`). Scenario quantiles are the explicit exception: when both fractional depth and scenario payloads are in use, matching points of the quantile functions are interpolated instead of raw scenarios (`REQ-38`).

### Versioned consistency
Concurrent root reads and range reads are specified separately without mandating locks, copy-on-write, CAS, or epochs. Root reads must not observe partially propagated updates (`REQ-23`), while ranges overlapping subtree reweighting must use a single version across the complete range (`REQ-40`).

### Independent axes
Groupby and time hierarchies share leaf-level source data but remain independently maintained. Intersection queries compose axis decompositions and must not require a precomputed cross-product cube.

## Risks / Trade-offs
- Exact scenario vectors consume memory proportional to the configured scenario count at every exact node. Optional sketches bound memory but make quantile results approximate.
- Dynamic insertion/removal and fixed-index canonical range decomposition can pull the implementation toward different tree layouts. The implementation must demonstrate both behaviors without weakening query guarantees.
- Cross-process structural sharing and browser model transport require stable serialization and synchronization boundaries; concrete protocols remain deferred until implementation planning selects dependencies.
- The source complexity claim for canonical decomposition is interpreted as finding the decomposition in `O(log_b n)` plus the cost of visiting or returning its canonical nodes.

## Migration Plan
This is a greenfield specification. Apply capabilities incrementally in dependency order: payload contracts, core tree, scenario risk, multidimensional composition, consistency/sharing, then optional integrations.

## Open Questions
- Which mergeable quantile sketch will be the first supported implementation?
- Which memory layout and synchronization primitive will satisfy cross-language shared-memory reads?
- Which serializable model protocol will be the initial dashboard integration target?
- What depth convention and boundary behavior apply to target-depth range queries?
- What confidence model, sign convention, and covariance formulas define parametric, component, and marginal VaR?
- Which node-size metric controls sketch compression?
- Does shared-memory mode always require non-Julia readers, or only when cross-process persistence is enabled?
- How will `MonoidPayload` supply the skewness and kurtosis needed by Cornish-Fisher estimation when its required fields include only first and second moments?
- How are scenario and factor index identities represented for alignment checks?
- Under what historical-window update can a sibling subtree be unaffected?
