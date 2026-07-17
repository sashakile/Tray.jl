# EARS Specification: RiskTree.jl

A hierarchical aggregation library, written in Julia, for portfolio risk analysis and scenario simulation. It supports efficient recomputation of statistics at different levels of detail (e.g. per-position, per-desk, whole-portfolio; per-day, per-month) over a large set of underlying positions/scenarios.

## 0. Background & Motivation

Portfolio risk systems need to answer questions like "what is the VaR of this book?" at many different granularities (single position, desk, firm-wide) and many different cuts (by book, by geography, by risk factor, by time window), and need those answers to update quickly as trades change or new scenarios are generated — without recomputing everything from the raw position/scenario data on every query.

This creates two distinct kinds of statistics, which this library treats differently:

1. **Monoidal (mergeable) statistics** — sum, count, mean, variance, and linear risk-factor exposures. These can be merged bottom-up: the aggregate of a parent node can always be computed as an associative combination of its children's aggregates, with no loss of information. This makes them cheap to precompute and roll up through a tree.
2. **Non-monoidal statistics** — Value-at-Risk (VaR), Conditional VaR / Expected Shortfall (CVaR/ES), and other quantile-based measures. These are *not* simply additive across sub-portfolios, because sub-portfolio P&Ls are correlated (this is exactly what diversification means). The standard way around this is to keep the underlying data these statistics are computed *from* — either a full P&L scenario vector (historical/Monte Carlo simulation) or a mergeable summary sketch of the distribution (e.g. t-digest) — mergeable instead, and derive VaR/CVaR/quantiles from that merged data at query time, rather than storing the risk statistic itself as a node value.

The library's core data structure is therefore a tree (an n-ary segment tree / hierarchical rollup structure, conceptually similar to image mipmaps or OLAP rollup cubes) where:
- **Leaves** represent individual positions or the finest time/scenario granularity.
- **Internal nodes** hold a payload computed by merging their children's payloads, bottom-up.
- **Different node payload types** are used depending on what's being aggregated: simple running statistics (count/sum/sum-of-squares) for monoidal stats, factor exposure vectors for parametric risk, and full P&L scenario vectors (or compressed sketches of them) for scenario-based VaR/CVaR.
- **Multiple independent trees** ("axes") can be built over the same underlying leaf data — e.g. one tree organized by book/desk/firm, another by time, another by risk-factor bucket — so that a query can roll up along whichever axis (or combination of axes) the user is currently viewing, similar to slicing an OLAP cube.
- The structure is designed to support **interactive use** (e.g. a dashboard where a user pans/zooms/drills into different books, time windows, or factor cuts) with query and update costs that scale logarithmically with the number of leaves rather than linearly.

This document specifies the required behavior of a Julia library, `RiskTree.jl`, implementing this structure, using the EARS (Easy Approach to Requirements Syntax) notation: Ubiquitous, Event-driven, State-driven, Optional-feature, Unwanted-behavior, and Complex requirement patterns. Each requirement is independently testable and is tagged with a stable ID (`REQ-n`) for traceability.

---

## 1. Scope & Definitions

- **Node**: a vertex in the aggregation tree holding a `payload` and pointers to children.
- **Leaf**: a node with no children, representing a single position/instrument/atomic time bucket.
- **Payload**: the data stored per node — a `MonoidPayload` (count, sum, sumsq, min, max) and/or a `ScenarioPayload` (P&L vector over a fixed scenario set) and/or an `ExposurePayload` (factor exposure vector).
- **Merge function**: an associative, closed binary operation `combine(a::T, b::T)::T` for a given payload type `T`.
- **LOD (level of detail)**: tree depth at which a query is answered.
- **Groupby axis**: an independent hierarchy (e.g. book → desk → firm) over which the same leaf data can be rolled up.
- **Scenario set**: a fixed, ordered set of market scenarios (historical or simulated) shared across all nodes in a scenario tree.

---

## 2. Ubiquitous Requirements

*(always active, no trigger — "the system shall")*

- **REQ-1**: The library shall represent the aggregation structure as an `n`-ary tree parameterized by payload type `T <: AbstractPayload`.
- **REQ-2**: The library shall require every payload type `T` used as a tree node to implement `combine(::T, ::T)::T` and `identity(::Type{T})::T`, and shall verify associativity is the caller's responsibility (not runtime-checked).
- **REQ-3**: The library shall compute each internal node's payload as `combine` folded over its children's payloads, bottom-up, at build time.
- **REQ-4**: The library shall support at minimum three built-in payload types: `MonoidPayload` (count, sum, sumsq, min, max), `ScenarioPayload{S}` (dense P&L vector of length `S`), and `ExposurePayload{K}` (factor exposure vector of length `K`).
- **REQ-5**: The library shall derive `mean`, `variance`, `stddev` from `MonoidPayload` at read time without storing them directly.
- **REQ-6**: The library shall derive quantile-based statistics (VaR, CVaR/ES, arbitrary quantile) from `ScenarioPayload` at read time by sorting or partial-sorting the stored P&L vector, without storing VaR/CVaR as node fields.
- **REQ-7**: The library shall guarantee that `combine` for `ScenarioPayload` and `ExposurePayload` is exact elementwise vector addition, introducing no approximation error at any tree depth.
- **REQ-8**: The library shall organize independent groupby hierarchies (e.g. book, geography, factor bucket) and the time hierarchy as separate `RiskTree` instances sharing the same leaf-level scenario matrix, rather than a single materialized cross-product cube.
- **REQ-9**: The library shall provide an `O(log_b n)` update path from any leaf to the root, where `b` is the tree's branching factor.
- **REQ-10**: The library shall provide range/subtree queries that decompose an arbitrary index range into a minimal set of canonical nodes, consistent with standard segment-tree decomposition.

---

## 3. Event-Driven Requirements

*(When \<trigger\>, the system shall \<response\>)*

- **REQ-11**: When a leaf's payload is updated (e.g. a position's exposure or scenario P&L changes), the system shall recompute and update the payload of every ancestor node on the path to the root.
- **REQ-12**: When a caller invokes a range query at a target depth `d`, the system shall decompose the query range into the minimal set of canonical nodes at or above depth `d` and return `combine` folded over those nodes.
- **REQ-13**: When a caller requests a statistic not natively stored on the payload (e.g. VaR at a given confidence level from a `ScenarioPayload`), the system shall compute it on demand from the merged payload without mutating the tree.
- **REQ-14**: When a new leaf is inserted into a tree, the system shall rebalance or extend the tree structure and update all affected ancestor payloads.
- **REQ-15**: When a leaf is removed, the system shall recompute all affected ancestor payloads to exclude the removed leaf's contribution.
- **REQ-16**: When a caller supplies a factor covariance matrix `Σ` alongside a node's `ExposurePayload` exposure vector `w`, the system shall compute parametric portfolio variance as `wᵀΣw` and derive parametric VaR from it.
- **REQ-17**: When a caller requests component/marginal VaR for a node, the system shall compute it from the correlation (or covariance) between that node's scenario vector and its ancestor's scenario vector, without requiring a separate stored statistic.
- **REQ-18**: When a caller reweights a subtree (e.g. a stress-test scenario changes position weights), the system shall recompute only the reweighted subtree and its ancestors, not the full tree.
- **REQ-19**: When a caller requests a fractional-depth (interpolated) LOD query, the system shall compute results at `floor(d)` and `ceil(d)` and linearly interpolate the underlying payload fields before deriving any statistic.
- **REQ-20**: When the leaf-level scenario matrix is regenerated (e.g. new Monte Carlo draw or historical window shift), the system shall rebuild affected `ScenarioPayload` trees bottom-up without requiring the caller to manually invalidate cached nodes.

---

## 4. State-Driven Requirements

*(While \<state\>, the system shall \<behavior\>)*

- **REQ-21**: While a `ScenarioPayload` tree is configured with sketch-based compression (e.g. above a configurable node-size threshold), the system shall store a mergeable sketch (t-digest or equivalent) instead of the full scenario vector for nodes above that threshold.
- **REQ-22**: While sketch-based compression is active for a node, the system shall report the sketch's configured error bound alongside any quantile/VaR/CVaR value derived from it.
- **REQ-23**: While a tree is open for concurrent reads during a leaf update, the system shall guarantee readers observe either the pre-update or post-update root payload, never a partially-updated intermediate state.
- **REQ-24**: While operating in shared-memory mode (multiple Julia processes or a Julia + non-Julia process sharing the same tree), the system shall serve reads without requiring full deserialization of the shared structure.
- **REQ-25**: While a tree instance has more than one groupby axis registered against the same leaf scenario matrix, the system shall keep each axis's tree independently updatable without requiring the others to be rebuilt.

---

## 5. Optional Feature Requirements

*(Where \<feature is included\>, the system shall \<behavior\>)*

- **REQ-26**: Where cross-process shared-memory persistence is enabled, the system shall expose the tree via a memory-mapped, structurally-shared persistent data structure, such that a separate process (e.g. a JVM/Clojure process or a Node.js process) can read the same tree without requiring the full structure to be deserialized or re-transmitted.
- **REQ-27**: Where the library is integrated with a browser-based dashboard via a kernel-agnostic widget protocol (e.g. an anywidget-style transport, in which frontend and backend state are kept in sync through a shared serializable model object with `get`/`set` and `on("change:...")` semantics), the system shall expose query results (current viewport aggregate, current LOD) through such a model-compatible getter/setter, so that a frontend state change (e.g. pan/zoom) can trigger a new range query without additional glue code.
- **REQ-28**: Where scenario generation via a factor model is enabled, the system shall compute a node's scenario P&L on demand as `(node's exposure vector) · (factor scenario matrix)` rather than requiring leaf-level scenario simulation for every position.
- **REQ-29**: Where lazy propagation is enabled for range updates (e.g. bulk reweighting of an entire subtree), the system shall defer per-leaf recomputation and apply the aggregate update directly to the subtree root, resolving lazily on next read.
- **REQ-30**: Where a caller opts into moment-based tail estimation (Cornish-Fisher expansion) instead of full scenario storage, the system shall compute approximate VaR from `MonoidPayload` moments alone, with an explicit warning that this assumes near-Gaussian behavior.

---

## 6. Unwanted Behavior Requirements

*(If \<trigger\>, then the system shall \<mitigation\>)*

- **REQ-31**: If a caller attempts to register a payload type `T` that does not implement `combine`, then the system shall raise a compile-time or construction-time error rather than silently falling back to a default merge.
- **REQ-32**: If a caller requests a statistic that requires the full scenario distribution (e.g. exact median) from a node whose payload has been sketch-compressed, then the system shall return the sketch-derived approximation together with its error bound, and shall not silently present it as exact.
- **REQ-33**: If two `ScenarioPayload` or `ExposurePayload` vectors of mismatched length or misaligned scenario/factor indexing are merged, then the system shall raise an error rather than merging misaligned elements.
- **REQ-34**: If a query range falls outside the bounds of the tree's leaf index, then the system shall raise a bounds error rather than returning a partial or zero-padded result silently.
- **REQ-35**: If concurrent writers attempt to update the same leaf simultaneously in shared-memory mode, then the system shall serialize the updates (e.g. via CAS/epoch-based retry) rather than allowing a lost update.
- **REQ-36**: If a caller requests VaR/CVaR directly from a `MonoidPayload`-only node (no scenario or sketch data present), then the system shall raise an informative error indicating the required payload type is absent, rather than returning a fabricated value.

---

## 7. Complex Requirements

*(compound trigger/state combinations)*

- **REQ-37**: While a tree is configured for historical-simulation VaR, when the underlying historical window advances by one period, the system shall shift the leaf-level scenario matrix, recombine all affected `ScenarioPayload` nodes bottom-up, and invalidate any cached quantile results for those nodes, while leaving unaffected sibling subtrees untouched.
- **REQ-38**: Where fractional-depth interpolation is enabled and a `ScenarioPayload` tree is in use, when a caller requests an interpolated-LOD quantile, the system shall interpolate the quantile function at matching probability levels between `floor(d)` and `ceil(d)` rather than interpolating raw scenario values, and shall document that this is an approximation, not an exact statistic.
- **REQ-39**: While multiple groupby axes and a time axis are all registered against the same leaf scenario matrix, when a caller requests a slice at the intersection of a groupby cut and a time range, the system shall compute the result as a composition of each axis's independent range-decomposition query rather than materializing a full cross-product cube.
- **REQ-40**: If a stress-test reweighting is applied to a subtree while a concurrent reader is executing a range query that spans that subtree, then the system shall ensure the reader's result reflects a single consistent version (pre- or post-reweight) of the entire spanned range, not a mix of both.

---

## 8. Non-Functional Requirements

- **REQ-41**: The system shall achieve `O(log_b n)` time complexity for point updates and canonical-node range decomposition, where `b` is the configured branching factor.
- **REQ-42**: The system shall achieve `O(n)` time complexity for full-tree bottom-up construction from `n` leaves.
- **REQ-43**: The system shall keep per-node `MonoidPayload` and `ExposurePayload` memory footprint constant (independent of subtree size).
- **REQ-44**: The system shall keep per-node `ScenarioPayload` memory footprint bounded either by the fixed scenario count `S` (exact mode) or by the configured sketch compression parameter (approximate mode), never growing with subtree size beyond that bound.

---

## 9. Traceability Notes

- Monoidal tier (sum/mean/variance/exposure) → REQ-4, REQ-5, REQ-7, REQ-16.
- Non-monoidal tier (VaR/CVaR/quantiles) → REQ-4, REQ-6, REQ-17, REQ-21–22, REQ-30, REQ-36.
- Groupby/factor rollup → REQ-8, REQ-25, REQ-39.
- Interactive LOD / viz integration → REQ-12, REQ-19, REQ-27, REQ-38.
- Scenario generation → REQ-20, REQ-28, REQ-37.
- Concurrency / cross-process shared-memory persistence → REQ-23, REQ-24, REQ-26, REQ-35, REQ-40.
