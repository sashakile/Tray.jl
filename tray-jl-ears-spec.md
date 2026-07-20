# EARS Specification: Tray.jl

Tray (tree + array) is a domain-neutral Julia library that pairs authoritative ordered leaf storage with a balanced aggregation index. It supports efficient recomputation of summaries at multiple levels of detail over changing data.

## 0. Background & Motivation

Telemetry, time-series, image-tile, spatial, and categorical systems need summaries at many granularities and cuts, and need those answers to update quickly without rescanning every source value.

This creates two distinct kinds of summaries, which Tray treats differently:

1. **Mergeable summaries** — sum, count, extrema, moments, vectors, and user-defined associative payloads. A parent summary is computed from its children's summaries.
2. **Sample-derived statistics** — quantiles and tail means require aligned samples or a bounded approximation. Tray therefore retains either a full aligned sample vector or an aligned-sum sketch that preserves sample pairing. Ordinary distribution-union sketches are not conforming because they discard alignment.

The library's core data structure is therefore a tree (an n-ary segment tree / hierarchical rollup structure, conceptually similar to image mipmaps or OLAP rollup cubes) where:
- **Leaves** occupy authoritative ordered array slots and represent atomic source values.
- **Internal nodes** hold a payload computed by merging their children's payloads, bottom-up.
- **Different payload types** summarize scalar observations, aligned arrays, or samples; arbitrary lawful payloads remain first-class.
- **Multiple independent indices** ("axes") can summarize the same immutable leaf IDs by time, space, category, or another hierarchy without materializing a cross-product.
- The structure supports interactive range, level-of-detail, and multidimensional queries with logarithmic search and update costs.

This document specifies the required behavior of a Julia library, `Tray.jl`, implementing this structure, using the EARS (Easy Approach to Requirements Syntax) notation: Ubiquitous, Event-driven, State-driven, Optional-feature, Unwanted-behavior, and Complex requirement patterns. Each requirement is independently testable and is tagged with a stable ID (`REQ-n`) for traceability.

---

## 1. Scope & Definitions

- **Leaf array**: authoritative ordered storage for leaf records. Stable leaf IDs are distinct from mutable array rank.
- **Aggregation index**: a balanced tree whose leaves reference array slots and whose internal nodes cache summaries; it is not a second source of leaf truth.
- **Node**: a vertex in the aggregation index holding a cached summary and child references.
- **Leaf**: an array record containing one atomic source value and immutable ID.
- **Payload**: an arbitrary type `T` with lawful `combine` and schema-bound identity; built-ins include scalar summaries, aligned arrays, and samples.
- **Merge function**: an associative, closed binary operation `combine(a::T, b::T)::T` for a given payload type `T`.
- **LOD (level of detail)**: tree depth at which a query is answered.
- **Axis**: an independent hierarchy over which the same leaf data can be summarized.
- **Sample set**: a fixed ordered set of sample IDs shared across aligned sample payloads.
- **Leaf ID**: an immutable, never-reused identifier independent of a leaf's current 1-based rank in deterministic leaf order.
- **Tree schema**: immutable dimensions, ordered identifiers, numeric type, and identity-relevant configuration shared by every payload in one tree.
- **Dataset revision**: an immutable version that prevents data, axes, caches, or compressed representations from different snapshots being combined in one query.

---

## 2. Ubiquitous Requirements

*(always active, no trigger — "the system shall")*

- **REQ-1**: The library shall pair an authoritative non-empty ordered leaf array with a balanced `n`-ary aggregation index parameterized by arbitrary payload type `T` and branching factor `b ≥ 2`. Index leaves shall reference array slots and internal nodes shall cache summaries. Construction, insertion, removal, update, and rebalance shall atomically preserve one schema, dataset revision, and snapshot; a maximum leaf depth of `O(log_b n)`; immutable leaf IDs; deterministic child order and balancing tie-breaks; and 1-based indices defined as ranks in current array order. Array growth or compaction may relocate slots but shall preserve IDs, order, snapshot isolation, and all index references.
- **REQ-2**: The library shall require every payload type `T` to implement closed `combine(::T, ::T)::T` and schema-aware `identity(schema)::T`. For every schema-valid `x`, both `combine(identity(schema), x) == x` and `combine(x, identity(schema)) == x` shall hold. Associativity remains the payload implementer's documented responsibility and is not runtime-checked; construction shall reject schema mismatch.
- **REQ-3**: The library shall compute each internal payload by folding `combine` over children in deterministic left-to-right order, bottom-up. Floating-point incremental recomputation and rebuilds shall use that same reduction order, a configured absolute/relative tolerance, and a deterministic rebuild or explicit error when accumulated divergence exceeds tolerance.
- **REQ-4**: The library shall support convenience types `ScalarSummary` (count, sum, sumsq, min, max), positive-length `SamplePayload{S}`, and positive-length `AlignedArrayPayload{K}` without restricting user-defined lawful `T`. All observations and array elements shall be finite. Count-zero scalar identity shall uniquely use zero sums and `minimum=+Inf`, `maximum=-Inf`; these sentinels are the only permitted non-finite stored values. Non-empty states shall have finite, consistent sums/extrema; optional higher moments shall add consistent mergeable third- and fourth-power sums.
- **REQ-5**: The library shall derive mean, population variance `sumsq/count - mean²`, and population standard deviation at read time without storing them; requesting these from count-zero identity shall raise a domain error.
- **REQ-6**: For a finite sample `x` of length `S`, the library shall define empirical quantile `q_p(x)` as sorted element `max(1, ceil(pS))` and upper-tail mean as `(1/(1-p))∫_p^1 q_u(x)du`, including fractional boundary mass. These statistics shall be derived on demand and never stored as node fields.
- **REQ-7**: Exact `SamplePayload` and `AlignedArrayPayload` combination shall use elementwise addition in immutable identifier order under REQ-3's deterministic reduction and tolerance/rebuild policy, introducing no additional tree-depth-dependent approximation.
- **REQ-8**: Independent categorical and ordered hierarchies shall be separate aggregation indices over the same immutable leaf IDs and dataset revision, without a materialized cross-product cube. Each axis shall maintain revisioned node/cut-to-leaf-ID sets and reverse leaf membership maps.
- **REQ-9**: The library shall provide an `O(log_b n)` update path from any leaf to the root, where `b` is the tree's branching factor.
- **REQ-10**: The library shall decompose an in-bounds, non-empty, closed 1-based range `[lo, hi]` into the minimal exact non-overlapping set of canonical nodes, with no complete sibling set replaceable by its parent.

---

## 3. Event-Driven Requirements

*(When \<trigger\>, the system shall \<response\>)*

- **REQ-11**: When a leaf value is updated, the system shall atomically update its authoritative array record and recompute every cached ancestor summary on the path to the root.
- **REQ-12**: Root depth shall be zero and child depth shall increase by one. When a caller supplies integer target depth `d` in `[0,h]`, the system shall use the minimal canonical nodes at depth at most `d` and fold them with `combine`; a range not exactly representable at that depth shall fail rather than include outside leaves.
- **REQ-13**: When a caller requests a derived statistic not stored in a payload, the system shall compute it on demand from the merged payload without mutating the index.
- **REQ-14**: When a leaf is inserted at a requested array boundary, the system shall assign a never-reused immutable ID, shift later ranks, deterministically grow or rebalance the index, preserve existing IDs and order, update affected summaries and references, and atomically restore REQ-1's invariants. Insertion into an empty dataset is excluded by the non-empty contract unless construction creates the first leaf.
- **REQ-15**: When a leaf is removed, the system shall retire and never reuse its ID, close the array gap while preserving remaining order, update affected summaries and references, deterministically compact or rebalance storage, and atomically restore REQ-1's invariants. Removing the sole leaf shall fail before mutation.
- **REQ-16**: When a caller supplies a finite aligned vector `w` and finite symmetric positive-semidefinite matrix `M`, the system shall compute the quadratic projection `wᵀMw`; dimensions and ordered IDs shall match exactly.
- **REQ-17**: For aligned finite node and ancestor sample vectors `N` and `A`, the system shall compute population covariance and normalized covariance contribution `cov(N,A)/σ_A` when ancestor population standard deviation is positive. Misalignment or zero ancestor variance shall fail.
- **REQ-18**: When a caller supplies payload-specific `reweight(::T, weight)::T`, the system shall apply it to the subtree leaves and recompute only that subtree and its ancestors; an undefined operation shall fail before mutation.
- **REQ-19**: When a caller requests a fractional-depth LOD query focused on a leaf ID or current index, the system shall interpolate only schema-equal values returned by an explicitly declared affine projection at the adjacent ancestors and apply the projection's declared result interpretation. Numeric raw payload fields shall never be interpolated merely because they are numeric; sample quantiles are governed by REQ-38.
- **REQ-20**: When the leaf-level aligned sample matrix is regenerated, the system shall create a new immutable dataset revision, rebuild affected sample indices bottom-up, invalidate old-revision caches, and atomically publish the new revision without manual invalidation.

---

## 4. State-Driven Requirements

*(While \<state\>, the system shall \<behavior\>)*

- **REQ-21**: A sample node shall have exactly one sealed representation: `Exact(values, sample_ids, dataset_revision)` or `Compressed(sketch, sample_ids, dataset_revision, config_id)`. Threshold transitions, every operand pairing, ordered sketch combination, identity, associativity bounds, sample pairing, revision/configuration compatibility, reconstruction from retained or immutable reloadable source, and atomic failure behavior shall follow the capability contract; ordinary distribution-union merging is forbidden.
- **REQ-22**: While compression is active, every quantile or tail-mean result shall return its value, `approximate=true`, configuration provenance, and cumulative absolute rank-error bound composed across promotions, merges, and query. Tail means shall report the rank-uncertainty envelope over their quantile integral and integrate finite value envelopes into an interval when available; otherwise the value-error bound shall be explicitly unavailable.
- **REQ-23**: Every mutation, topology change, lazy flush, rebuild, cache/configuration or representation transition, and persistent publication shall stage and atomically publish one immutable snapshot epoch. Multi-node reads shall pin one epoch; same- or different-leaf writers sharing ancestors shall preserve a serial order without lost updates; every failure shall discard all staged state and preserve the prior snapshot.
- **REQ-24**: While shared-memory mode is active, compatible readers shall query mapped node/header regions without reconstructing a private whole-tree object. A common conformance fixture and deterministic counters for mapped/touched bytes, decoded/visited nodes, combinations, emitted canonical nodes, retries, and full deserialization shall verify direct access and complexity claims.
- **REQ-25**: While multiple axes share one leaf source, each aggregation index shall remain independently updatable without rebuilding or revision-changing other axes unless the shared source itself changes.

---

## 5. Optional Feature Requirements

*(Where \<feature is included\>, the system shall \<behavior\>)*

- **REQ-26**: Where persistence is enabled, the versioned mapped format shall identify magic, version, byte order, numeric types, dimensions, schema/configuration provenance, offsets, checksums, and committed epoch. Upgrades shall copy-transform-validate and atomically cut over to a separate target; interruption or failure shall leave the old mapping active and unchanged, and unsupported/incomplete mappings shall be rejected.
- **REQ-27**: Where dashboard integration is enabled, a serializable model shall expose `viewport_range`, `requested_depth`, `request_revision`, `aggregate`, `effective_depth`, `error`, and `result_revision`. Input changes shall atomically capture both inputs with increasing revisions; overlapping computation shall be latest-wins, and only the newest revision may atomically publish a success or error tuple.
- **REQ-28**: Where aligned matrix projection is enabled, the system shall compute a length-`S` sample vector as row vector `w` times a finite `K × S` matrix whose ordered dimension IDs exactly match `w`; malformed or misaligned matrices shall fail.
- **REQ-29**: Where lazy propagation is enabled, transformations shall form an ordered action: identity acts trivially, composition preserves submission order, and action distributes over `combine`; reweighting uses the same action with weight `1` as identity. Deferred descendants shall be resolved on read, and all tags shall flush before topology, schema/configuration, serialization, persistence, or representation boundaries.
- **REQ-30**: Where moment-based quantile estimation is selected, the system shall use first-through-fourth power sums, population central moments, skewness, and excess kurtosis with the documented Cornish-Fisher formula, mark the result approximate, and warn that it assumes near-Gaussian behavior. Insufficient observations or moments, non-positive variance, or invalid probability shall fail.

---

## 6. Unwanted Behavior Requirements

*(If \<trigger\>, then the system shall \<mitigation\>)*

- **REQ-31**: If a caller attempts to register a payload type `T` that does not implement `combine`, then the system shall raise a compile-time or construction-time error rather than silently falling back to a default merge.
- **REQ-32**: If a caller requests a statistic that requires the full sample distribution from a node whose payload has been sketch-compressed, then the system shall return the sketch-derived approximation together with its error bound, and shall not silently present it as exact.
- **REQ-33**: Sample and aligned-array vectors shall carry immutable, ordered, unique identifiers. Mismatched lengths or non-identical identifier sequences shall cause an alignment error; missing or duplicate identifiers shall fail at construction.
- **REQ-34**: If any query range endpoint is out of bounds or `lo > hi`, the system shall raise a bounds error rather than return an empty, partial, or padded result.
- **REQ-35**: If concurrent writers attempt to update the same leaf simultaneously in shared-memory mode, then the system shall serialize the updates (e.g. via CAS/epoch-based retry) rather than allowing a lost update.
- **REQ-36**: If a caller requests a sample-derived statistic from a `ScalarSummary`-only node with no sample or sketch data, then the system shall raise an informative error indicating the required payload capability is absent rather than fabricate a value.

---

## 7. Complex Requirements

*(compound trigger/state combinations)*

- **REQ-37**: While rolling samples are configured, when the sample window advances, the system shall create a new dataset revision, identify changed immutable leaf IDs, rebuild changed leaves and ancestors bottom-up, invalidate old-revision caches, and atomically publish the new revision. A sibling remains unchanged exactly when it has no changed descendant; revisions shall never combine in one query.
- **REQ-38**: Where fractional-depth interpolation is enabled for a sample index, a valid focus leaf, finite depth, and probability shall produce the two adjacent ancestors' REQ-6 quantiles at matching probability and linearly interpolate those quantiles rather than raw samples. The result shall be marked approximate and, if either ancestor is compressed, carry both ancestors' provenance and conservatively composed REQ-22 uncertainty.
- **REQ-39**: While multiple axes share a source, an intersection query shall pin one dataset revision, reject cross-version inputs, compute exact intersection of cut leaf-ID sets, order and coalesce IDs by current leaf rank, canonically decompose resulting ranges, and fold deterministically without visiting outside leaves or materializing a cross-product cube.
- **REQ-40**: If any mutation overlaps a range query, the reader shall use one complete pre- or post-mutation snapshot epoch across the entire range, never a mixture.

---

## 8. Non-Functional Requirements

- **REQ-41**: For fixed `b`, point updates shall take `O(log_b n)` time, and finding a range decomposition shall take `O(log_b n)` search time plus `O(k)` to visit or return its `k` canonical nodes.
- **REQ-42**: The system shall achieve `O(n)` time complexity for full-tree bottom-up construction from `n` leaves.
- **REQ-43**: The system shall keep per-node `ScalarSummary` and fixed-dimension `AlignedArrayPayload` memory footprint constant, independent of subtree size.
- **REQ-44**: Each sample node shall use exactly one REQ-21 representation with storage bounded by fixed sample count `S` in exact mode or configured sketch parameter in compressed mode, independent of subtree leaf count. Retained/reloadable reconstruction source shall be accounted separately with location and dataset revision in configuration provenance.

---

## 9. Traceability Notes (Core)

- Generic payload algebra and scalar/array summaries → REQ-2–7, REQ-16–17, REQ-43.
- Aligned samples, quantiles, and tail means → REQ-6–7, REQ-20–22, REQ-30, REQ-32–33, REQ-36–38, REQ-44.
- Multiaxis rollups → REQ-8, REQ-25, REQ-39.
- Interactive LOD / viz integration → REQ-12, REQ-19, REQ-27, REQ-38.
- Sample generation and rolling windows → REQ-20, REQ-28, REQ-37.
- Concurrency / cross-process shared-memory persistence → REQ-23, REQ-24, REQ-26, REQ-35, REQ-40.

---

## Addendum A: Compiler-IR-Based Automatic Incrementalization

### A.0 Background & Motivation

REQ-11 and REQ-18 require updates along affected ancestor paths. Lawful `combine` remains the canonical operation and full bottom-up recomputation remains the correctness oracle. This optional capability derives exact finite-change update functions from Julia IR when possible; generated code is an optimization only and is never a substitute for `combine`.

The change-action account in Cai, Giarrusso, Rendel, and Ostermann's “A Theory of Changes for Higher-Order Languages” is related and analogous, but does not by itself establish this implementation's correctness. Correctness is established by the finite-change soundness law, immutable old-state protocol, and comparison with canonical recomputation.

### A.1 Scope of this Addendum

`Tray.Incremental` supports pure, effect-free straight-line and branch-stable programs over a registered subset of operations. Changed control flow, dynamic calls, recursion, general loops, exceptions, mutation, aliasing, globals, RNG, I/O, tasks, atomics, and foreign calls are boundaries in v1. LLVM transformation, differential-dataflow bindings, replacement of canonical `combine`, and claims that rank operations are impossible to incrementalize are out of scope.

### A.2 Ubiquitous Requirements

- **REQ-A1**: For every supported value type `T`, `Tray.Incremental` shall define `Change{T}`, `zero_change(old)`, `valid_change(old, Δ)`, `apply_change(old, Δ)`, and `compose_change(old, Δ1, Δ2)`. Valid changes shall satisfy identity and sequential composition, and every generated or registered rule shall satisfy `apply_change(f(old_args...), Δf(old_args, old_result, Δargs)) == f(map(apply_change, old_args, Δargs)...)` under documented equality semantics.
- **REQ-A2**: Derivation shall use an internal provider interface for capability probing and IR retrieval. The default optional provider shall use documented IRTools `IR`, `code_ir`, and `@code_ir` surfaces and support only matrix-listed Julia versions 1.10 or newer. V1 shall test Julia 1.10.x, 1.11.x, and 1.12.x, each with an exact compatible IRTools 0.4.x patch pinned in that CI row; later minors are unsupported until a pinned row passes.
- **REQ-A3**: For transitively covered IR, `Tray.Incremental` shall emit an exact finite-change function. Additive multiplication shall include `old_x*Δy + Δx*old_y + Δx*Δy`; sine shall use `sin(apply_change(old_x, Δx)) - sin(old_x)`, never a linearization.
- **REQ-A4**: Rules shall be stored in immutable monotonically revisioned snapshots keyed by complete callable type and argument tuple. Lookup shall use Julia-like applicability/specificity, reject incomparable ambiguity, reject duplicate registration by default, require explicit replacement, and require exact-key removal; derived artifacts shall retain the revision used.
- **REQ-A5**: Analysis shall return only sealed `Derived(artifact, coverage)` or `Rejected(diagnostics, coverage)`. Every classified derivation failure, including unavailable/incompatible providers, shall be a typed diagnostic inside `Rejected`; no third result state or raw thrown provider/compiler failure is permitted. Coverage shall join transitively over all reachable callees using `Covered < Boundary < Rejected`; rejection shall expose no callable partial artifact, and only fully `Covered` artifacts may run.
- **REQ-A6**: Built-in rules shall obey REQ-A1. `min` and `max` shall recompute old and changed results using Julia operation semantics and encode the change between them, including deterministic argument-order ties, signed zero, NaN, infinities, and other non-finite values. Validation shall use domain-neutral scalar-summary, aligned-array, sample, and user-defined payload fixtures against canonical `combine` and full recomputation; optional adapters may add integration fixtures without defining compiler conformance.

### A.3 Event-Driven Requirements

- **REQ-A7**: When selecting an update strategy, one common adapter shall retain lawful `combine` as canonical and generated `Δf` as optional. The adapter shall receive immutable old child, sibling, parent, and result snapshots and retain full canonical recomputation as oracle and fallback.
- **REQ-A8**: When deriving or invoking an artifact, v1 shall accept only pure, effect-free straight-line or branch-stable programs whose old and changed inputs follow identical control-flow edges. Changed flow, dynamic calls, recursion, unsupported loops, exceptions, mutation, aliasing, globals, RNG, I/O, tasks, atomics, or `ccall` shall reject or use canonical fallback; only explicitly provider-unrolled fixed-shape loops are allowed.
- **REQ-A9**: When using a generated update on an ancestor path, the system shall compute all changes privately and publish only the complete validated path in the core REQ-23 snapshot transaction. Any boundary, staleness, exception, or oracle mismatch shall discard private results and recompute with canonical `combine` before publication.

### A.4 Unwanted Behavior Requirements

- **REQ-A10**: If an operation lacks a rule or exact supported change representation, the system shall return a trace boundary and diagnostic rather than fabricate an approximation. Rank operations are boundaries in v1 unless explicit state and exact or explicitly bounded rules are registered; the system shall not claim they are impossible in principle.
- **REQ-A11**: Public failures shall be classified as `UnsupportedEnvironment`, `IRProviderUnavailable`, `IRProviderIncompatible`, `MethodMissing`, `MethodAmbiguous`, `RuleMissing`, `RuleAmbiguous`, `UnsupportedEffect`, `ControlFlowChanged`, `MutableCapture`, `StaleArtifact`, `InvalidChange`, `OracleMismatch`, or `GenerationFailure`. Each shall include phase, known callable/method identity, known source location, remediation, and preserved provider/compiler cause.

### A.5 Non-Functional / Explicit Non-Goals

- **REQ-A12**: `Tray.Incremental` shall not transform or depend on LLVM IR; derivation remains at the Julia-IR provider boundary.
- **REQ-A13**: `Tray.Incremental` shall neither reimplement nor bind to `differential-dataflow`/`timely-dataflow`; runtime incremental maintenance of iterative or recursive relation queries is a separate undertaking.
- **REQ-A14**: `Tray.Incremental` shall be interoperable with, but not dependent on, dependency-graph or memoization frameworks. Such a framework may wrap either canonical or generated update strategies without changing their correctness contract or owning artifact invalidation.
- **REQ-A15**: V1 may cover broadcast only when lowering yields fixed-shape, transitively covered, effect-free scalar operations. Dynamic axes, allocation/mutation effects, or uncovered helpers shall be boundaries.
- **REQ-A16**: Every artifact shall bind method instance and valid world range, full argument types, immutable closure-capture snapshot, registry revision, provider identity/version, Julia/backend/toolchain identity, and payload schema/version. Mutable captures shall reject; invocation mismatch or expired validity shall return `StaleArtifact` and rederive or use canonical fallback before generated code runs.
- **REQ-A17**: IRTools shall remain optional and shall be probed only by `derive`. Module loading, registry operations, and invocation of a non-stale existing artifact shall remain usable without importing or probing IRTools; artifact validation shall compare stored provider metadata. Derivation without IRTools shall return `Rejected` containing `IRProviderUnavailable` with installation guidance.

### A.6 Traceability Notes (Addendum)

- Finite-change algebra, provider, generation, registry, and analysis → REQ-A1–A5.
- Exact rules and core payload baselines → REQ-A6.
- Canonical strategy, v1 boundary, and atomic tree integration → REQ-A7–A9.
- Diagnostics and non-goals → REQ-A10–A14.
- Broadcast, artifact provenance, and optional-provider lifecycle → REQ-A15–A17.

---

## Addendum B: Bucketed Attribution and Waterfalls

Attribution decomposes an observed total into named additive components. The same algebra supports telemetry-source contribution, forecast-vs-actual bridges, cohort contribution, operational waterfalls, and optional financial P&L attribution. It uses Tray's normal array, aggregation-index, query, transaction, and multi-axis contracts; no domain-specific tree is required.

- **REQ-45**: The library shall provide `AttributionPayload{K}` containing a finite bucket vector of positive length `K`, a finite `realized_total`, and an immutable ordered unique bucket-ID tuple of length `K`, satisfying REQ-2's `combine` and schema-aware `identity` contract. Combination shall add corresponding buckets and realized totals under REQ-3's deterministic reduction and tolerance/rebuild policy. Identity shall contain zero buckets and zero total. Misaligned bucket IDs or lengths shall fail under REQ-33.
- **REQ-46**: Every `AttributionPayload` shall reconcile `sum(buckets)` with `realized_total` under REQ-3's configured tolerance. A schema may designate one residual bucket; construction shall add any out-of-tolerance gap to that bucket, or fail when no residual is designated. Combination shall preserve reconciliation, and no gap shall be silently absorbed or dropped.
- **REQ-47**: Every attribution schema shall record an immutable convention as `Direct` for externally supplied buckets or `Allocated(method, ordered_factor_ids)` for derived buckets. Allocated methods shall include sequential allocation with declared factor order and symmetric allocation. Changing convention shall require a new schema and Tray instance; REQ-A16 shall bind the same provenance when generated updates are used.
- **REQ-48**: Derived ratios over attribution or other additive data shall not be stored or combined. The library shall derive ratios at read time from additive numerator and denominator components at the queried node, depth, or multi-axis cut; a zero denominator shall raise a domain error.

### B.1 Traceability Notes

- Payload algebra, deterministic reduction, and alignment → REQ-2–3, REQ-7, REQ-33, REQ-45–46.
- Schema, transaction, and generated-artifact provenance → REQ-1, REQ-23, REQ-A16, REQ-47.
- Read-time derivation and all existing query paths → REQ-5, REQ-8, REQ-12, REQ-25, REQ-27, REQ-39, REQ-48.

---

## Addendum F: Optional Financial-Risk Interpretation

This optional adapter assigns finance-specific meanings to domain-neutral core values. It is not required to construct, query, update, persist, or incrementalize Tray.

- **FIN-1**: Where financial loss interpretation is enabled, the adapter shall interpret aligned profit-and-loss sample `P` as losses `L=-P`, define VaR at confidence `c` as core quantile `q_c(L)`, and define Expected Shortfall as the core upper-tail mean, including fractional boundary mass.
- **FIN-2**: Where Gaussian factor risk is enabled, the adapter shall interpret REQ-16's `wᵀMw` as portfolio variance and compute zero-mean Gaussian VaR `Φ⁻¹(c)sqrt(wᵀMw)` for `c` in `(0.5,1)`.
- **FIN-3**: Where contribution risk is enabled, the adapter shall scale REQ-17's normalized covariance contribution by `Φ⁻¹(c)` for marginal VaR and by node scale for component VaR.
- **FIN-4**: Where factor-scenario generation is enabled, the adapter shall interpret REQ-28's aligned row-vector/matrix projection as scenario P&L and require exact ordered factor-ID alignment.
- **FIN-5**: Where moment-based financial tail estimation is enabled, the adapter shall apply REQ-30 to loss moments, report Cornish-Fisher VaR as approximate, and expose the near-Gaussian assumption.
- **FIN-6**: Where historical financial simulation is enabled, the adapter shall interpret REQ-37's rolling samples as historical scenarios while retaining the core dataset-revision and atomic-publication contract.
