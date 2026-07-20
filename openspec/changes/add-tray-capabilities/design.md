## Context
Tray pairs an authoritative ordered leaf array with a balanced aggregation index. The source EARS document defines 44 domain-neutral requirements spanning core data structures, numerical behavior, optional storage modes, concurrency, and integrations; finance-specific interpretations are isolated behind an optional adapter.

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
The requirements are split by user-visible responsibility rather than by EARS sentence form. Core tree mechanics, payload arithmetic, sample analytics, multidimensional composition, consistency/sharing, dashboard integration, and optional financial interpretations can therefore evolve and be tested independently.

Normative ownership is unique: `aggregation-tree` owns REQ-1–3, 9–15, 18–19, 29, 31, 34, and 41–42; `payload-statistics` owns REQ-4–5, 7, 16, 33, and 43; `sample-analytics` owns REQ-6, 17, 20–22, 28, 30, 32, 36–38, and 44; `multidimensional-rollups` owns REQ-8, 25, and 39; `consistent-sharing` owns REQ-23–24, 26, 35, and 40; `dashboard-integration` owns REQ-27; and `financial-risk` owns FIN-1–FIN-6. The root EARS source is authoritative; capability files provide test scenarios without changing IDs.

### Array and index ownership
The ordered leaf array is authoritative for leaf values, IDs, and order. Aggregation-index leaves reference array slots; internal nodes cache summaries. Every mutation stages array records, slot references, topology, and cached summaries under one schema, dataset revision, and snapshot. Growth and compaction may relocate slots but cannot change stable IDs or observable order.

### Exactness and approximation
`SamplePayload` and `AlignedArrayPayload` combination uses deterministic identifier-order addition in exact mode, subject to IEEE arithmetic and an explicit tolerance/rebuild policy. Sample storage is a sealed exact/compressed representation. Mixed combinations promote exact operands; all sketches carry algorithm/configuration/source provenance and cumulative rank uncertainty, and every representation transition rebuilds from retained or immutable reloadable source. Rank uncertainty yields a tail-mean interval only when finite value envelopes are available; otherwise value error is explicitly unavailable.

### Fractional level of detail
The root has depth zero and child depth increases by one. Integer target-depth range queries return an exact folded aggregate and therefore have the same aggregate at every valid decomposition depth. Fractional depth is instead a focused level-of-detail operation: for a selected leaf, it interpolates between explicitly declared affine projections of the two adjacent ancestors on that leaf's root-to-leaf path, never arbitrary raw payload fields. Sample quantiles interpolate matching points of the two quantile functions instead of raw samples (`REQ-38`).

### Statistical conventions
Sample quantiles use a documented nearest-rank empirical convention. Upper-tail mean is the empirical quantile integral with fractional boundary mass. Normalized covariance contribution uses population covariance and ancestor standard deviation. Moment-based Cornish-Fisher estimation requires skewness and excess kurtosis, so optional higher-moment `ScalarSummary` schemas include mergeable third- and fourth-power sums. Finance-specific interpretations are owned only by `financial-risk`.

### Approximation contract
Sketch compression uses subtree leaf count as its threshold metric. A conforming sample sketch must preserve sample-ID alignment and satisfy an aligned-sum merge contract: combining sketches of aligned vectors approximates a sketch of their elementwise sum. Distribution-union merging is non-conforming because it discards pairing. A sketch advertises an absolute rank-error bound `ε` in `[0, 1]`; approximate quantile and tail-mean results report that rank bound and do not imply a value-error bound. The concrete aligned-sum sketch algorithm remains an implementation choice.

### Versioned consistency
All mutations—including topology, lazy flushes, rebuilds, cache/configuration changes, and persistence publication—stage and atomically publish one immutable snapshot epoch. Every multi-node read pins one epoch. Optimistic retry, locking, or copy-on-write remain implementation choices, but same- or different-leaf writers sharing ancestors cannot lose updates and every failure rolls back all staged state.

### Independent axes
Categorical and ordered hierarchies share immutable leaf IDs and revisioned membership maps but remain independently maintained. Intersection queries reject cross-revision inputs, intersect exact leaf-ID sets, order/coalesce indices, and deterministically fold canonical decompositions without a cross-product cube.

### Alignment and rolling updates
Sample and general aligned dimensions carry immutable, ordered, unique identifiers. Combination requires exact identifier-sequence equality. A rolling-window advancement identifies changed leaves; every changed leaf and ancestor is rebuilt, while a sibling is unaffected exactly when it has no changed descendant. A common-window shift can affect the whole index without implying that an unaffected sibling must exist.

### Shared-memory and dashboard contracts
Shared-memory mode is a live, potentially non-durable mapping that uses the same versioned binary layout as optional persistent mappings. The layout identifies format version, byte order, numeric types, dimensions, offsets, and snapshot epoch. Every language implementation declared compatible with a format version must pass the same conformance fixture.

Persistent upgrades use copy-transform-validate-atomic-cutover with rollback to the untouched old mapping. Mapped reads expose deterministic decoding/work counters and prohibit whole-tree private reconstruction. Dashboard integration uses monotonically increasing request revisions, latest-wins completion, and atomic result/error publication.

### Algebra and deferred work
Payload identity is constructed from the immutable tree schema and must satisfy both identity laws. Lazy/reweight transformations form an ordered monoid action and homomorphism over `combine`; pending tags are flushed before topology, schema/configuration, representation, serialization, or persistence boundaries. Fractional interpolation is allowed only through an explicitly declared affine projection and result interpretation.

## Risks / Trade-offs
- Exact sample vectors consume memory proportional to configured sample count at every exact node. Optional sketches bound memory but make quantile results approximate.
- Dynamic insertion/removal and fixed-index canonical range decomposition can pull the implementation toward different tree layouts. The implementation must demonstrate both behaviors without weakening query guarantees.
- Cross-process structural sharing and browser model transport require stable serialization and synchronization boundaries; their contracts are fixed here while concrete dependencies remain deferred.
- The source complexity claim treats branching factor `b` as fixed and is interpreted as finding the decomposition in `O(log_b n)` plus the unavoidable cost of visiting or returning its canonical nodes.

## Migration Plan
This is a greenfield specification. Apply capabilities incrementally in dependency order: payload contracts, ordered array and aggregation index, sample analytics, multidimensional composition, consistency/sharing, then optional integrations including financial interpretation.
