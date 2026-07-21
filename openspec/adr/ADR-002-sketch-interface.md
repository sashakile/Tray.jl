# ADR-002: Compressed-Sample Algorithm Interface and Greenwald-Khanna Sketch

**Status:** Approved
**Author:** sasha
**Date:** 2026-07-20
**Tickets:** TRAYS-a7f, TRAYS-x6z
**Requirements:** REQ-21, REQ-22, REQ-32, REQ-44

## Context

Sample nodes can store exact samples or compressed sketches. The sketch
algorithm must be conforming (aligned-sum merge, preserved pairing,
deterministic promotion) and provide tunable rank-error bounds. Future
performance or accuracy requirements may motivate switching algorithms; the
design must not commit to one sketch implementation at the architecture level.

## Decision

### 1. Pluggable Sketch Interface

The sketch type is parameterized at the schema level. Every sketch implements a
fixed contract. The term `merge` is used for sketch combination (as opposed to
`combine` which is reserved for exact payload aggregation in `TrayBase`).

```julia
abstract type SampleSketch{T} end

# Required operations
merge(a::S, b::S) where {S<:SampleSketch} -> S
identity(::Type{S}) where {S<:SampleSketch} -> S
quantile(sketch::S, p::Float64) -> (value::T, approx::Bool, error_bound::Float64)
tail_mean(sketch::S, p::Float64) -> (value::T, approx::Bool, error_bound::Float64, envelope::Union{Nothing, Tuple{T,T}})
rank_error_bound(sketch::S) -> Float64
storage_bytes(sketch::S) -> Int
```

This interface lets us swap algorithms by changing the schema configuration.
The tree code never touches sketch internals — it only calls `merge` and
`identity`.

### 2. Initial Implementation: Greenwald-Khanna (GK)

The first conforming sketch is **Greenwald-Khanna** (GK)
[[GK01]](https://doi.org/10.1016/S0022-0000(02)00025-1), a deterministic,
mergeable, order-statistics sketch.

**Properties:**
- **Algorithm summary:** Maintains a sorted list of tuples `(value, g, Δ)`
  where `g` is the minimum rank and `Δ` is the rank error bound per element.
  On insert, new tuples are inserted in sorted order and adjacent tuples are
  merged when `g + Δ` stays within the error budget. The implementation ticket
  (TRAYS-x6z) MUST include the full algorithm pseudocode with compression
  criteria.
- **Merge:** Two GK sketches are merged by unioning their tuple lists, sorting
  by value, then compressing with the same compression criteria.
- **Rank-error bound:** Tunable `ε` in (0, 1). Storage is
  `O((1/ε) log(ε n))` tuples. For ε=0.01 and n up to 10⁹, at most ~1,600
  tuples. Each tuple is `(Float64, Int64, Int64)` = 24 bytes → ~38 KB worst
  case.
- **Strengths:** Simplest conforming sketch. Deterministic. Well-understood.
  Trivial to implement correctly.
- **Weaknesses:** Merge is O(k log k) where k is the combined tuple count. Not
  as memory-efficient as KLL or as tail-accurate as t-digest.

**Storage bound (REQ-44):** Maximum `O((1/ε) log(ε n))` tuples. For ε=0.01 and
n ≤ 10⁹, at most ~1,600 tuples ≈ 38 KB. The configured `max_storage_bytes`
MUST be at least this (see §4 for conflict resolution).

### 3. Future Algorithm Swaps

The interface makes swapping straightforward:
- **t-digest:** Implement `SampleSketch` interface. Uses buffer-based merging.
  Better tail accuracy. Slightly larger constant factors.
- **DDSketch:** Implement `SampleSketch` interface. Logarithmic relative error.
  Good for high-dynamic-range data.
- **MergingDigest:** Implement `SampleSketch` interface. Apache DataSketches
  proven implementation. Strong rank-error guarantees.
- **KLL:** Implement `SampleSketch` interface. Optimal space. More complex to
  implement.

No algorithm change requires modifying the tree, query, or payload code.

### 4. Sketch Configuration

Configuration is stored in the schema as a tuple
`(algorithm_id::Symbol, epsilon::Float64, max_storage_bytes::Int)`.

**Validation rules:**
- `epsilon` MUST be in `(0, 1)`. epsilon = 0 is rejected (would require
  unbounded storage). epsilon < 0 is rejected (meaningless). epsilon ≥ 1 is
  rejected (no precision).
- `max_storage_bytes` MUST be ≥ 1. Zero is rejected.
- If `epsilon` and `max_storage_bytes` conflict (the epsilon's implied storage
  exceeds the limit), construction MUST fail with an informative error
  specifying the minimum required storage for the given epsilon.

**Examples:**
- `(:gk, 0.01, 65536)` — 1% rank error, 64 KB budget (~38 KB used)
- `(:gk, 0.001, 262144)` — 0.1% rank error, 256 KB budget
- `(:tdigest, 0.01, 65536)` — same budget, different algorithm

The algorithm ID selects the concrete implementation at construction time.

## Consequences

**Accepted trade-offs:**
- Pluggable interface adds a level of indirection but means algorithm swaps
  never touch tree code.
- GK is not the most space-efficient sketch (KLL is), but it is the simplest
  correct implementation and can be swapped later.
- ε=0.01 gives 1% rank error with ~38 KB storage — acceptable for the POC.

**Rejected alternatives:**
- Single hardcoded sketch: rejected for lack of optionality.
- KLL as first implementation: rejected for implementation complexity; GK is
  simpler to validate.
- t-digest as first implementation: rejected because its merge properties are
  less well-understood than GK's for the aligned-sum contract.
- Distribution-union merging (DDSketch's waterfall, t-digest's buffer merge
  without pairing): rejected as non-conforming per REQ-21.
