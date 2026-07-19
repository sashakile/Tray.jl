# EARS Specification: Tray.jl

A hierarchical aggregation library, written in Julia, for portfolio risk analysis and scenario simulation. It supports efficient recomputation of statistics at different levels of detail (e.g. per-position, per-desk, whole-portfolio; per-day, per-month) over a large set of underlying positions/scenarios.

## 0. Background & Motivation

Portfolio risk systems need to answer questions like "what is the VaR of this book?" at many different granularities (single position, desk, firm-wide) and many different cuts (by book, by geography, by risk factor, by time window), and need those answers to update quickly as trades change or new scenarios are generated — without recomputing everything from the raw position/scenario data on every query.

This creates two distinct kinds of statistics, which this library treats differently:

1. **Monoidal (mergeable) statistics** — sum, count, mean, variance, and linear risk-factor exposures. These can be merged bottom-up: the aggregate of a parent node can always be computed as an associative combination of its children's aggregates, with no loss of information. This makes them cheap to precompute and roll up through a tree.
2. **Non-monoidal statistics** — Value-at-Risk (VaR), Conditional VaR / Expected Shortfall (CVaR/ES), and other quantile-based measures. These are *not* simply additive across sub-portfolios, because sub-portfolio P&Ls are correlated (this is exactly what diversification means). The library therefore retains either the full aligned P&L scenario vector or an aligned-sum sketch that preserves scenario pairing while approximating elementwise vector addition. Ordinary distribution-union sketches such as ordinary t-digest merging are not conforming because they discard cross-position dependence. VaR/CVaR/quantiles are derived from the resulting representation at query time rather than stored as node values.

The library's core data structure is therefore a tree (an n-ary segment tree / hierarchical rollup structure, conceptually similar to image mipmaps or OLAP rollup cubes) where:
- **Leaves** represent individual positions or the finest time/scenario granularity.
- **Internal nodes** hold a payload computed by merging their children's payloads, bottom-up.
- **Different node payload types** are used depending on what's being aggregated: simple running statistics (count/sum/sum-of-squares) for monoidal stats, factor exposure vectors for parametric risk, and full P&L scenario vectors (or compressed sketches of them) for scenario-based VaR/CVaR.
- **Multiple independent trees** ("axes") can be built over the same underlying leaf data — e.g. one tree organized by book/desk/firm, another by time, another by risk-factor bucket — so that a query can roll up along whichever axis (or combination of axes) the user is currently viewing, similar to slicing an OLAP cube.
- The structure is designed to support **interactive use** (e.g. a dashboard where a user pans/zooms/drills into different books, time windows, or factor cuts) with query and update costs that scale logarithmically with the number of leaves rather than linearly.

This document specifies the required behavior of a Julia library, `Tray.jl`, implementing this structure, using the EARS (Easy Approach to Requirements Syntax) notation: Ubiquitous, Event-driven, State-driven, Optional-feature, Unwanted-behavior, and Complex requirement patterns. Each requirement is independently testable and is tagged with a stable ID (`REQ-n`) for traceability.

---

## 1. Scope & Definitions

- **Node**: a vertex in the aggregation tree holding a `payload` and pointers to children.
- **Leaf**: a node with no children, representing a single position/instrument/atomic time bucket.
- **Payload**: the data stored per node — a `MonoidPayload` (count, sum, sumsq, min, max) and/or a `ScenarioPayload` (P&L vector over a fixed scenario set) and/or an `ExposurePayload` (factor exposure vector).
- **Merge function**: an associative, closed binary operation `combine(a::T, b::T)::T` for a given payload type `T`.
- **LOD (level of detail)**: tree depth at which a query is answered.
- **Groupby axis**: an independent hierarchy (e.g. book → desk → firm) over which the same leaf data can be rolled up.
- **Scenario set**: a fixed, ordered set of market scenarios (historical or simulated) shared across all nodes in a scenario tree.
- **Leaf ID**: an immutable, never-reused identifier independent of a leaf's current 1-based rank in deterministic leaf order.
- **Tree schema**: immutable dimensions, ordered identifiers, numeric type, and identity-relevant configuration shared by every payload in one tree.
- **Source/scenario epoch**: immutable version identifiers that prevent data, axes, caches, or compressed representations from different scenario snapshots being combined in one query.

---

## 2. Ubiquitous Requirements

*(always active, no trigger — "the system shall")*

- **REQ-1**: The library shall represent aggregation as a non-empty balanced `n`-ary tree parameterized by payload type `T <: AbstractPayload` and branching factor `b ≥ 2`. Construction, insertion, and removal shall preserve a maximum leaf depth of `O(log_b n)`, immutable leaf IDs, deterministic child order and balancing tie-breaks, and 1-based indices defined as ranks in current deterministic leaf order.
- **REQ-2**: The library shall require every payload type `T` to implement closed `combine(::T, ::T)::T` and schema-aware `identity(schema)::T`. For every schema-valid `x`, both `combine(identity(schema), x) == x` and `combine(x, identity(schema)) == x` shall hold. Associativity remains the payload implementer's documented responsibility and is not runtime-checked; construction shall reject schema mismatch.
- **REQ-3**: The library shall compute each internal payload by folding `combine` over children in deterministic left-to-right order, bottom-up. Floating-point incremental recomputation and rebuilds shall use that same reduction order, a configured absolute/relative tolerance, and a deterministic rebuild or explicit error when accumulated divergence exceeds tolerance.
- **REQ-4**: The library shall support `MonoidPayload` (count, sum, sumsq, min, max), positive-length `ScenarioPayload{S}`, and positive-length `ExposurePayload{K}`. All observations and vector elements shall be finite. Count-zero monoidal identity shall uniquely use zero sums and `minimum=+Inf`, `maximum=-Inf`; these sentinels are the only permitted non-finite stored values. Non-empty states shall have finite, consistent sums/extrema; optional tail moments shall add consistent mergeable third- and fourth-power sums.
- **REQ-5**: The library shall derive mean, population variance `sumsq/count - mean²`, and population standard deviation at read time without storing them; requesting these from count-zero identity shall raise a domain error.
- **REQ-6**: For a finite sample `x` of length `S`, the library shall define empirical quantile `q_p(x)` as sorted element `max(1, ceil(pS))`. For P&L `P`, losses are `L=-P`; VaR at confidence `c` is `q_c(L)`, and empirical ES is the quantile integral `(1/(1-c))∫_c^1 q_u(L)du`, including fractional boundary mass. These statistics shall be derived on demand and never stored as node fields.
- **REQ-7**: Exact `ScenarioPayload` and `ExposurePayload` combination shall use elementwise addition in immutable identifier order under REQ-3's deterministic reduction and tolerance/rebuild policy, introducing no additional tree-depth-dependent approximation.
- **REQ-8**: Independent groupby and time hierarchies shall be separate tree instances over the same immutable leaf IDs and source epoch, without a materialized cross-product cube. Each axis shall maintain epoch-versioned node/cut-to-leaf-ID sets and reverse leaf membership maps.
- **REQ-9**: The library shall provide an `O(log_b n)` update path from any leaf to the root, where `b` is the tree's branching factor.
- **REQ-10**: The library shall decompose an in-bounds, non-empty, closed 1-based range `[lo, hi]` into the minimal exact non-overlapping set of canonical nodes, with no complete sibling set replaceable by its parent.

---

## 3. Event-Driven Requirements

*(When \<trigger\>, the system shall \<response\>)*

- **REQ-11**: When a leaf's payload is updated (e.g. a position's exposure or scenario P&L changes), the system shall recompute and update the payload of every ancestor node on the path to the root.
- **REQ-12**: Root depth shall be zero and child depth shall increase by one. When a caller supplies integer target depth `d` in `[0,h]`, the system shall use the minimal canonical nodes at depth at most `d` and fold them with `combine`; a range not exactly representable at that depth shall fail rather than include outside leaves.
- **REQ-13**: When a caller requests a statistic not natively stored on the payload (e.g. VaR at a given confidence level from a `ScenarioPayload`), the system shall compute it on demand from the merged payload without mutating the tree.
- **REQ-14**: When a leaf is inserted, the system shall assign a never-reused immutable ID, deterministically extend or rebalance the tree, preserve existing IDs, update affected ancestors, and restore REQ-1's height bound.
- **REQ-15**: When a leaf is removed, the system shall retire and never reuse its ID, update affected ancestors, deterministically reindex remaining leaves, and restore REQ-1's height bound.
- **REQ-16**: When a caller supplies covariance matrix `Σ` and exposure `w`, the system shall compute variance `wᵀΣw` and zero-mean Gaussian VaR `Φ⁻¹(c)sqrt(wᵀΣw)` for `c` in `(0.5,1)`. `Σ` shall be finite, symmetric, positive semidefinite, `K × K`, and exactly factor-ID aligned with `w`.
- **REQ-17**: For aligned node and ancestor loss vectors `N` and `A`, the system shall use population covariance and ancestor population standard deviation to compute marginal VaR `Φ⁻¹(c)cov(N,A)/σ_A` and component VaR as node scale times marginal VaR. Invalid confidence, misalignment, or zero ancestor variance shall fail.
- **REQ-18**: When a caller supplies payload-specific `reweight(::T, weight)::T`, the system shall apply it to the subtree leaves and recompute only that subtree and its ancestors; an undefined operation shall fail before mutation.
- **REQ-19**: When a caller requests a fractional-depth LOD query focused on a leaf ID or current index, the system shall interpolate only schema-equal values returned by an explicitly declared affine projection at the adjacent ancestors and apply the projection's declared result interpretation. Numeric raw payload fields shall never be interpolated merely because they are numeric; scenario quantiles are governed by REQ-38.
- **REQ-20**: When the leaf-level scenario matrix is regenerated, the system shall create a new immutable source epoch, rebuild affected scenario trees bottom-up, invalidate old-epoch caches, and atomically publish one new scenario epoch without requiring manual invalidation.

---

## 4. State-Driven Requirements

*(While \<state\>, the system shall \<behavior\>)*

- **REQ-21**: A scenario node shall have exactly one sealed representation: `Exact(values, scenario_ids, source_epoch)` or `Compressed(sketch, scenario_ids, source_epoch, config_id)`. Threshold transitions, every exact/compressed operand pairing, ordered sketch combination, identity, associativity bounds, scenario pairing, epoch/configuration compatibility, reconstruction from retained or immutable reloadable source, and atomic failure behavior shall follow the capability contract; ordinary distribution-union merging is forbidden.
- **REQ-22**: While compression is active, every quantile, VaR, or ES result shall return its value, `approximate=true`, configuration provenance, and cumulative absolute rank-error bound composed across promotions, merges, and query. ES shall report the rank-uncertainty envelope over its quantile integral and integrate finite value envelopes into an ES interval when available; otherwise the value-error bound shall be explicitly unavailable.
- **REQ-23**: Every mutation, topology change, lazy flush, rebuild, cache/configuration or representation transition, and persistent publication shall stage and atomically publish one immutable snapshot epoch. Multi-node reads shall pin one epoch; same- or different-leaf writers sharing ancestors shall preserve a serial order without lost updates; every failure shall discard all staged state and preserve the prior snapshot.
- **REQ-24**: While shared-memory mode is active, compatible readers shall query mapped node/header regions without reconstructing a private whole-tree object. A common conformance fixture and deterministic counters for mapped/touched bytes, decoded/visited nodes, combinations, emitted canonical nodes, retries, and full deserialization shall verify direct access and complexity claims.
- **REQ-25**: While multiple axes share one leaf scenario source, each axis tree shall remain independently updatable without rebuilding or version-changing other axes unless the shared source itself changes.

---

## 5. Optional Feature Requirements

*(Where \<feature is included\>, the system shall \<behavior\>)*

- **REQ-26**: Where persistence is enabled, the versioned mapped format shall identify magic, version, byte order, numeric types, dimensions, schema/configuration provenance, offsets, checksums, and committed epoch. Upgrades shall copy-transform-validate and atomically cut over to a separate target; interruption or failure shall leave the old mapping active and unchanged, and unsupported/incomplete mappings shall be rejected.
- **REQ-27**: Where dashboard integration is enabled, a serializable model shall expose `viewport_range`, `requested_depth`, `request_revision`, `aggregate`, `effective_depth`, `error`, and `result_revision`. Input changes shall atomically capture both inputs with increasing revisions; overlapping computation shall be latest-wins, and only the newest revision may atomically publish a success or error tuple.
- **REQ-28**: Where factor-model generation is enabled, the system shall compute length-`S` scenario P&L as exposure row vector `w` times a finite `K × S` factor scenario matrix whose ordered factor IDs exactly match `w`; malformed or misaligned matrices shall fail.
- **REQ-29**: Where lazy propagation is enabled, transformations shall form an ordered action: identity acts trivially, composition preserves submission order, and action distributes over `combine`; reweighting uses the same action with weight `1` as identity. Deferred descendants shall be resolved on read, and all tags shall flush before topology, schema/configuration, serialization, persistence, or representation boundaries.
- **REQ-30**: Where moment-based tail estimation is selected, the system shall use first-through-fourth power sums, population loss central moments, skewness, and excess kurtosis with the documented Cornish-Fisher formula, mark the result approximate, and warn that it assumes near-Gaussian behavior. Insufficient observations/moments, non-positive variance, or invalid confidence shall fail.

---

## 6. Unwanted Behavior Requirements

*(If \<trigger\>, then the system shall \<mitigation\>)*

- **REQ-31**: If a caller attempts to register a payload type `T` that does not implement `combine`, then the system shall raise a compile-time or construction-time error rather than silently falling back to a default merge.
- **REQ-32**: If a caller requests a statistic that requires the full scenario distribution (e.g. exact median) from a node whose payload has been sketch-compressed, then the system shall return the sketch-derived approximation together with its error bound, and shall not silently present it as exact.
- **REQ-33**: Scenario and factor vectors shall carry immutable, ordered, unique identifiers. Mismatched lengths or non-identical identifier sequences shall cause an alignment error; missing or duplicate identifiers shall fail at construction.
- **REQ-34**: If any query range endpoint is out of bounds or `lo > hi`, the system shall raise a bounds error rather than return an empty, partial, or padded result.
- **REQ-35**: If concurrent writers attempt to update the same leaf simultaneously in shared-memory mode, then the system shall serialize the updates (e.g. via CAS/epoch-based retry) rather than allowing a lost update.
- **REQ-36**: If a caller requests VaR/CVaR directly from a `MonoidPayload`-only node (no scenario or sketch data present), then the system shall raise an informative error indicating the required payload type is absent, rather than returning a fabricated value.

---

## 7. Complex Requirements

*(compound trigger/state combinations)*

- **REQ-37**: While historical simulation is configured, when the historical window advances, the system shall create a new source epoch, identify changed immutable leaf IDs, rebuild changed leaves and ancestors bottom-up, invalidate old-epoch caches, and atomically publish one new scenario epoch. A sibling remains unchanged exactly when it has no changed descendant; old and new epochs shall never combine in one query.
- **REQ-38**: Where fractional-depth interpolation is enabled for a scenario tree, a valid focus leaf, finite depth, and probability shall produce the two adjacent ancestors' REQ-6 quantiles at matching probability and linearly interpolate those quantiles rather than raw scenarios. The result shall be marked approximate and, if either ancestor is compressed, carry both ancestors' provenance and conservatively composed REQ-22 uncertainty.
- **REQ-39**: While multiple axes share a source, an intersection query shall pin one source/scenario epoch, reject cross-version inputs, compute exact intersection of cut leaf-ID sets, order and coalesce IDs by current leaf rank, canonically decompose resulting ranges, and fold deterministically without visiting outside leaves or materializing a cross-product cube.
- **REQ-40**: If any mutation overlaps a range query, the reader shall use one complete pre- or post-mutation snapshot epoch across the entire range, never a mixture.

---

## 8. Non-Functional Requirements

- **REQ-41**: For fixed `b`, point updates shall take `O(log_b n)` time, and finding a range decomposition shall take `O(log_b n)` search time plus `O(k)` to visit or return its `k` canonical nodes.
- **REQ-42**: The system shall achieve `O(n)` time complexity for full-tree bottom-up construction from `n` leaves.
- **REQ-43**: The system shall keep per-node `MonoidPayload` and `ExposurePayload` memory footprint constant (independent of subtree size).
- **REQ-44**: Each scenario node shall use exactly one REQ-21 representation with storage bounded by fixed scenario count `S` in exact mode or configured sketch parameter in compressed mode, independent of subtree leaf count. Retained/reloadable reconstruction source shall be accounted separately with location and epoch in configuration provenance.

---

## 9. Traceability Notes (Core)

- Monoidal tier (sum/mean/variance/exposure) → REQ-4, REQ-5, REQ-7, REQ-16.
- Non-monoidal tier (VaR/CVaR/quantiles) → REQ-4, REQ-6, REQ-17, REQ-21–22, REQ-30, REQ-36.
- Groupby/factor rollup → REQ-8, REQ-25, REQ-39.
- Interactive LOD / viz integration → REQ-12, REQ-19, REQ-27, REQ-38.
- Scenario generation → REQ-20, REQ-28, REQ-37.
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
- **REQ-A6**: Built-in rules shall obey REQ-A1. `min` and `max` shall recompute old and changed results using Julia operation semantics and encode the change between them, including deterministic argument-order ties, signed zero, NaN, infinities, and other non-finite values. Validation shall cover `MonoidPayload`, `ScenarioPayload`, and `ExposurePayload` against canonical `combine` and full recomputation.

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
