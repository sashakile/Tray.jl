# Architecture

Tray pairs an ordered leaf array with a balanced aggregation index. The
architecture follows the algebraic pattern of monoidal reduction: every payload
type implements `combine` (associative binary operation) and `identity` (unit),
giving the tree a well-defined root value for any collection of leaves.

## Tree Structure

The core data structure is an n-ary segment tree / hierarchical rollup, similar
to image mipmaps or OLAP rollup cubes:

- **Leaves** — individual values in stable array order (1-based)
- **Internal nodes** — payload computed by folding children via `combine`
- **Levels** — bottom-up array of levels; `levels[1]` = leaves, `levels[end]` = root
- **Payloads** — any type implementing the `combine`/`identity` contract

Construction folds `combine` over groups of `b` children deterministically in
O(n) time. A single leaf produces a depth-0 tree (root == leaf).

## Payload System

Every payload type implements:

```julia
TrayBase.combine(a::MyPayload, b::MyPayload) -> MyPayload
TrayBase.identity(schema::MySchema) -> MyPayload
```

Identity must satisfy both left and right identity laws for every schema-valid
value. The `Tray` constructor validates this for every leaf.

Two built-in payloads are provided:

| Payload | Fields | Use Case |
|---------|--------|----------|
| `ScalarSummary{T}` | count, sum, sumsq, min, max, (optional m3, m4) | Numeric statistics, streaming moments |
| `AttributionPayload{K,T}` | buckets Vector{T}, realized_total T | Contribution analysis, waterfall charts |

Custom payloads are first-class — extend `TrayBase.combine` and `TrayBase.identity`
for your own types. No schema registration or subtyping is required.

## Query & Update

- **Range query** — decomposes [lo, hi] into canonical O(log_b n) nodes using
  top-down decomposition; folds via `combine`
- **Depth-targeted query** — restricts canonical decomposition to a minimum node
  level; rejects ranges that cannot be represented at the given depth
- **Immutable update** — `update(tree, idx, value)` returns a new tree sharing
  unchanged sibling subtrees (copy-on-write, snapshot isolation)
- **In-place update** — `update!(tree, idx, value)` mutates the tree in-place;
  currently O(n) for all levels, path tracing is a POST-POC optimization

## Derived Metrics

Read-time derivation avoids storing mergeable ratio fields:

- `derived_mean(summary::ScalarSummary)` — returns `sum / count`
- `derive_ratio(payload::AttributionPayload, num_id, den_id)` — returns
  numerator/denominator bucket ratio
- Both throw `DomainError` when the denominator is zero

## Extension Pattern

To create a custom payload type:

```julia
struct MyPayload{T}
    value::T
end

struct MySchema{T}
    dummy::T
end

function TrayBase.combine(a::MyPayload{T}, b::MyPayload{T}) where {T}
    MyPayload{T}(a.value + b.value)
end

function TrayBase.identity(schema::MySchema{T}) where {T}
    MyPayload{T}(zero(T))
end

# Use in a tree
leaves = [MyPayload(1.0), MyPayload(2.0)]
t = Tree(leaves; b=2, schema=MySchema(0.0))
```

The tree constructor validates that every leaf satisfies the identity law for the
given schema — a non-conforming payload or schema mismatch is caught at
construction time.