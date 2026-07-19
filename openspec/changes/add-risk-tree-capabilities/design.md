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
`ScenarioPayload` and `ExposurePayload` combination uses deterministic identifier-order addition in exact mode, subject to IEEE arithmetic and an explicit tolerance/rebuild policy. Scenario storage is a sealed exact/compressed representation. Mixed combinations promote exact operands; all sketches carry algorithm/configuration/source provenance and cumulative rank uncertainty, and every representation transition rebuilds from retained or immutable reloadable source. Rank uncertainty yields an ES value interval only when finite value envelopes are available; otherwise the value-error bound is explicitly unavailable.

### Fractional level of detail
The root has depth zero and child depth increases by one. Integer target-depth range queries return an exact folded aggregate and therefore have the same aggregate at every valid decomposition depth. Fractional depth is instead a focused level-of-detail operation: for a selected leaf, it interpolates between explicitly declared affine projections of the two adjacent ancestors on that leaf's root-to-leaf path, never arbitrary raw payload fields. Scenario quantiles interpolate matching points of the two quantile functions instead of raw scenarios (`REQ-38`).

### Statistical conventions
Scenario quantiles use a documented nearest-rank empirical convention. VaR and Expected Shortfall operate on losses, with ES defined by the empirical quantile integral and fractional boundary mass, while factor VaR uses a zero-mean Gaussian model. Component and marginal scenario VaR use covariance with the ancestor loss vector.

Moment-based Cornish-Fisher estimation requires skewness and excess kurtosis. When that optional mode is enabled, `MonoidPayload` therefore includes mergeable third- and fourth-power sums in addition to its baseline fields. The baseline payload remains unchanged when the mode is disabled.

### Approximation contract
Sketch compression uses subtree leaf count as its threshold metric. A conforming scenario sketch must preserve scenario-index alignment and satisfy an aligned-sum merge contract: combining sketches of aligned vectors approximates a sketch of their elementwise sum. Ordinary distribution-union merging, including ordinary t-digest merging, is non-conforming because it discards cross-position scenario dependence. A sketch advertises an absolute rank-error bound `ε` in `[0, 1]`; approximate quantile, VaR, and Expected Shortfall results report that rank bound and do not imply a value-error bound. The concrete aligned-sum sketch algorithm remains an implementation choice.

### Versioned consistency
All mutations—including topology, lazy flushes, rebuilds, cache/configuration changes, and persistence publication—stage and atomically publish one immutable snapshot epoch. Every multi-node read pins one epoch. Optimistic retry, locking, or copy-on-write remain implementation choices, but same- or different-leaf writers sharing ancestors cannot lose updates and every failure rolls back all staged state.

### Independent axes
Groupby and time hierarchies share immutable leaf IDs and epoch-versioned membership maps but remain independently maintained. Intersection queries reject cross-epoch inputs, intersect exact leaf-ID sets, order/coalesce indices, and deterministically fold canonical decompositions without a cross-product cube.

### Alignment and historical updates
Scenario and factor dimensions carry immutable, ordered, unique identifiers. Combination requires exact identifier-sequence equality. A historical-window advancement identifies the leaves whose source series advanced; every changed leaf and ancestor is rebuilt, while a sibling is unaffected exactly when it has no changed descendant. A common-window shift can therefore affect the whole tree without implying that an unaffected sibling must exist.

### Shared-memory and dashboard contracts
Shared-memory mode is a live, potentially non-durable mapping that uses the same versioned binary layout as optional persistent mappings. The layout identifies format version, byte order, numeric types, dimensions, offsets, and snapshot epoch. Every language implementation declared compatible with a format version must pass the same conformance fixture.

Persistent upgrades use copy-transform-validate-atomic-cutover with rollback to the untouched old mapping. Mapped reads expose deterministic decoding/work counters and prohibit whole-tree private reconstruction. Dashboard integration uses monotonically increasing request revisions, latest-wins completion, and atomic result/error publication.

### Algebra and deferred work
Payload identity is constructed from the immutable tree schema and must satisfy both identity laws. Lazy/reweight transformations form an ordered monoid action and homomorphism over `combine`; pending tags are flushed before topology, schema/configuration, representation, serialization, or persistence boundaries. Fractional interpolation is allowed only through an explicitly declared affine projection and result interpretation.

## Risks / Trade-offs
- Exact scenario vectors consume memory proportional to the configured scenario count at every exact node. Optional sketches bound memory but make quantile results approximate.
- Dynamic insertion/removal and fixed-index canonical range decomposition can pull the implementation toward different tree layouts. The implementation must demonstrate both behaviors without weakening query guarantees.
- Cross-process structural sharing and browser model transport require stable serialization and synchronization boundaries; their contracts are fixed here while concrete dependencies remain deferred.
- The source complexity claim treats branching factor `b` as fixed and is interpreted as finding the decomposition in `O(log_b n)` plus the unavoidable cost of visiting or returning its canonical nodes.

## Migration Plan
This is a greenfield specification. Apply capabilities incrementally in dependency order: payload contracts, core tree, scenario risk, multidimensional composition, consistency/sharing, then optional integrations.
