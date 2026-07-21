# Examples

## 1. ScalarSummary — Numeric Statistics

Construct a tree from observation summaries, query ranges, and derive the mean.

```julia
using Tray

schema = ScalarSchema{Float64}(false)

# Leaf payloads summarizing groups of observations
leaves = [
    ScalarSummary(; schema, count=3, sum=6.0, sumsq=14.0, minimum=1.0, maximum=3.0),
    ScalarSummary(; schema, count=2, sum=5.0, sumsq=13.0, minimum=2.0, maximum=3.0),
    ScalarSummary(; schema, count=1, sum=10.0, sumsq=100.0, minimum=10.0, maximum=10.0),
    ScalarSummary(; schema, count=4, sum=-2.0, sumsq=10.0, minimum=-3.0, maximum=2.0),
    ScalarSummary(; schema, count=2, sum=3.0, sumsq=5.0, minimum=1.0, maximum=2.0),
]

tray = Tree(leaves; b=2, schema)

# Accessors
leaf_count(tray)       # 5
depth(tray)            # 3 (ceil(log_2 5))
root(tray).sum         # 22.0
root(tray).count       # 12

# Range query: first 3 leaves
r = range_query(tray, 1, 3)
r.count                # 6
r.sum                  # 21.0

# Derive the mean across the whole tree
derived_mean(root(tray))  # 22.0 / 12 ≈ 1.833
```

### Higher Moments

```julia
schema_hm = ScalarSchema{Float64}(true)

leaf = ScalarSummary(
    ; schema=schema_hm, count=5, sum=15.0, sumsq=55.0,
    minimum=1.0, maximum=5.0, m3=0.0, m4=34.0
)
# higher_moment=true stores skew and kurtosis components
```

## 2. AttributionPayload — Waterfall / Contribution Analysis

Track named buckets that reconcile with a realized total.

```julia
using Tray

schema = AttributionSchema(
    bucket_ids = (:pnl, :costs, :fees),
    tolerance = 1e-10,
    residual_bucket_id = nothing,
    convention = Direct(),
)

leaves = [
    AttributionPayload(; schema, buckets=[100.0, -70.0, 30.0], realized_total=60.0),
    AttributionPayload(; schema, buckets=[50.0, -20.0, 30.0], realized_total=60.0),
    AttributionPayload(; schema, buckets=[200.0, -150.0, 50.0], realized_total=100.0),
]

tray = Tree(leaves; b=2, schema)

# Root aggregates all leaves
root(tray).buckets         # [350.0, -240.0, 110.0]
root(tray).realized_total  # 220.0

# Read-time ratio derivation (never stored)
derive_ratio(root(tray), :pnl, :costs)   # 350.0 / -240.0 ≈ -1.458
derive_ratio(root(tray), :pnl, :fees)    # 350.0 / 110.0 ≈ 3.182

# Range query: second and third leaf only
r2 = range_query(tray, 2, 3)
r2.buckets                # [250.0, -170.0, 80.0]
```

### Reconciliation with Residual Bucket

When the sum of buckets differs slightly from `realized_total` (e.g., due to
rounding), a designated residual bucket absorbs the gap:

```julia
schema_r = AttributionSchema(
    bucket_ids = (:pnl, :costs, :residual),
    tolerance = 1e-6,
    residual_bucket_id = :residual,
    convention = Direct(),
)

# Gap of 0.5 automatically assigned to :residual
p = AttributionPayload(
    ; schema=schema_r, buckets=[100.0, -70.0, 0.0], realized_total=30.5
)
p.buckets   # [100.0, -70.0, 0.5] — gap absorbed
```

### Allocated Convention

When buckets are derived from simultaneously changing factors, declare the
allocation method and factor order:

```julia
schema_a = AttributionSchema(
    bucket_ids = (:rate, :volume, :mix),
    tolerance = 1e-10,
    residual_bucket_id = nothing,
    convention = Allocated(:sequential, [:price, :quantity, :product_mix]),
)

# Convention is immutable schema provenance
schema_a.convention  # Allocated(:sequential, [:price, :quantity, :product_mix])
```

## 3. Immutable Update (Snapshot Isolation)

The `update` function returns a new tree, leaving the original unchanged:

```julia
using Tray

schema = ScalarSchema{Float64}(false)
leaves = [ScalarSummary(; schema, count=1, sum=float(i), sumsq=float(i^2), minimum=float(i), maximum=float(i)) for i in 1:4]
t = Tree(leaves; b=2, schema)
original_root = root(t)

new_leaf = ScalarSummary(; schema, count=1, sum=99.0, sumsq=9801.0, minimum=99.0, maximum=99.0)
t2 = update(t, 2, new_leaf)

root(t)   # original — unchanged
root(t2)  # recomputed with leaf 2 replaced
```

## 4. Custom Payload

Any type with `combine` and `identity` works in a tree:

```julia
using Tray: TrayBase, Tree, root, range_query, combine, identity

struct MySum{T}
    value::T
end

struct MySumSchema{T}
    dummy::T
end

function TrayBase.combine(a::MySum{T}, b::MySum{T}) where {T}
    MySum{T}(a.value + b.value)
end

function TrayBase.identity(schema::MySumSchema{T}) where {T}
    MySum{T}(zero(T))
end

schema = MySumSchema(0.0)
leaves = [MySum(1.0), MySum(5.0), MySum(10.0)]
t = Tree(leaves; b=2, schema=schema)

root(t)  # MySum(16.0)
```

## 5. Property: Root Fold Oracle

For any payload type, the root always equals the direct leaf fold:

```julia
using Tray
using Tray: combine

schema = ScalarSchema{Float64}(false)
leaves = [ScalarSummary(; schema, count=1, sum=float(i), sumsq=float(i^2), minimum=float(i), maximum=float(i)) for i in 1:5]
t = Tree(leaves; b=2, schema)

# Verify: root == reduce(combine, leaves)
@assert root(t) == reduce(combine, leaves)
```

This holds for every tree structure regardless of branching factor `b` or
number of leaves, because `combine` is associative.

## 6. Depth-Targeted Range Query

Query at a specific aggregation depth instead of the full tree:

```julia
using Tray

schema = ScalarSchema{Float64}(false)
leaves = [ScalarSummary(; schema, count=1, sum=float(i), sumsq=float(i^2), minimum=float(i), maximum=float(i)) for i in 1:8]
t = Tree(leaves; b=2, schema)

# Depth 0 = root (full tree)
range_query(t, 1, 8; target_depth=0) == root(t)  # true

# Depth 1 = second level from root (nodes covering [1,4] and [5,8])
range_query(t, 1, 4; target_depth=1) == t.levels[3][1]  # true

# Depth 2 = third level from root (nodes covering [1,2], [3,4], etc.)
range_query(t, 1, 2; target_depth=2) == t.levels[2][1]  # true
```

A range that cannot be exactly represented at the given depth raises
`ArgumentError`.

## 7. Error Handling

Tray raises typed exceptions for invalid operations:

```julia
using Tray

schema = ScalarSchema{Float64}(false)
id = TrayBase.identity(schema)

# Empty leaf array
Tree(ScalarSummary[]; b=2, schema)           # ArgumentError

# Index out of bounds
Tree([id, id]; b=2, schema) |> t -> range_query(t, 0, 1)  # BoundsError

# Non-reconciling attribution (no residual bucket)
attr_schema = AttributionSchema(
    bucket_ids = (:a, :b),
    tolerance = 1e-10,
    residual_bucket_id = nothing,
    convention = Direct(),
)
AttributionPayload(; schema=attr_schema, buckets=[1.0, 2.0], realized_total=10.0)
# ArgumentError: bucket_sum does not reconcile

# Zero-denominator ratio
p = AttributionPayload(; schema=attr_schema, buckets=[0.0, 0.0], realized_total=0.0)
derive_ratio(p, :a, :b)   # DomainError: denominator is zero
```
