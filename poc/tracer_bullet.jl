#!/usr/bin/env julia --project
# Tracer-bullet POC: vertical slice through Tray
#
# Exercises: payload algebra → tree construction → update → range query
# with both ScalarSummary and AttributionPayload.
# If this runs without error, the core stack is wired correctly.

using Tray
using Tray: ScalarSchema, ScalarSummary, identity, combine, root, leaf_count, depth
using Tray: AttributionSchema, AttributionPayload, Direct, derive_ratio
using Tray: Tree

println("═══ Tracer-bullet POC ═══")
println()

# ── 1. ScalarSummary ──────────────────────────────────────────────
println("── ScalarSummary tree ──")

schema = ScalarSchema{Float64}(false)
leaves = [
    ScalarSummary(
        schema = schema,
        count = 3,
        sum = 6.0,
        sumsq = 14.0,
        minimum = 1.0,
        maximum = 3.0,
    ),
    ScalarSummary(
        schema = schema,
        count = 2,
        sum = 5.0,
        sumsq = 13.0,
        minimum = 2.0,
        maximum = 3.0,
    ),
    ScalarSummary(
        schema = schema,
        count = 1,
        sum = 10.0,
        sumsq = 100.0,
        minimum = 10.0,
        maximum = 10.0,
    ),
    ScalarSummary(
        schema = schema,
        count = 4,
        sum = -2.0,
        sumsq = 10.0,
        minimum = -3.0,
        maximum = 2.0,
    ),
    ScalarSummary(
        schema = schema,
        count = 2,
        sum = 3.0,
        sumsq = 5.0,
        minimum = 1.0,
        maximum = 2.0,
    ),
]

tray = Tree(leaves; b = 2, schema)
println("  Leaves:  $(leaf_count(tray))")
println("  Depth:   $(depth(tray))")
println("  Levels:  $(length(tray.levels))")
println("  Root:    count=$(root(tray).count), sum=$(root(tray).sum)")

# Verify root = fold of all leaves
expected = reduce(combine, leaves)
@assert root(tray) == expected "Root mismatch: $(root(tray)) != $(expected)"
println("  ✅ Root equals fold of all leaves")

# Range query: first 3 leaves
r = range_query(tray, 1, 3)
@assert r == combine(combine(leaves[1], leaves[2]), leaves[3])
println("  ✅ range_query(1, 3) == combine of first 3 leaves")

# Identity laws
id = identity(schema)
@assert combine(id, root(tray)) == root(tray)
@assert combine(root(tray), id) == root(tray)
println("  ✅ Identity laws hold on root")

# Update
new_leaf = ScalarSummary(
    schema = schema,
    count = 1,
    sum = 99.0,
    sumsq = 9801.0,
    minimum = 99.0,
    maximum = 99.0,
)
new_root = update!(tray, 3, new_leaf)
@assert new_root == root(tray)
@assert tray.levels[1][3] == new_leaf

updated_expected = reduce(combine, [leaves[1], leaves[2], new_leaf, leaves[4], leaves[5]])
@assert root(tray) == updated_expected
println("  ✅ update! recomputes ancestors correctly")

println()

# ── 2. AttributionPayload ─────────────────────────────────────────
println("── AttributionPayload tree ──")

attrib_schema = AttributionSchema(
    bucket_ids = (:pnl, :costs, :fees),
    tolerance = 1e-10,
    residual_bucket_id = nothing,
    convention = Direct(),
)

attrib_leaves = [
    AttributionPayload(
        schema = attrib_schema,
        buckets = [100.0, -70.0, 30.0],
        realized_total = 60.0,
    ),
    AttributionPayload(
        schema = attrib_schema,
        buckets = [50.0, -20.0, 30.0],
        realized_total = 60.0,
    ),
    AttributionPayload(
        schema = attrib_schema,
        buckets = [200.0, -150.0, 50.0],
        realized_total = 100.0,
    ),
]

attrib_tray = Tree(attrib_leaves; b = 2, schema = attrib_schema)
println("  Leaves:  $(leaf_count(attrib_tray))")
println("  Depth:   $(depth(attrib_tray))")
println(
    "  Root:    buckets=$(root(attrib_tray).buckets), realized=$(root(attrib_tray).realized_total)",
)

# Verify root = fold of all leaves
attrib_expected = reduce(combine, attrib_leaves)
@assert root(attrib_tray) == attrib_expected
println("  ✅ Root equals fold of all leaves")

# Range query
r2 = range_query(attrib_tray, 2, 3)
@assert r2 == combine(attrib_leaves[2], attrib_leaves[3])
println("  ✅ range_query(2, 3) == combine of leaves 2 and 3")

# Derive ratio from root
root_margin = derive_ratio(root(attrib_tray), :pnl, :costs)
pnl = 100.0 + 50.0 + 200.0   # 350
costs = -70.0 + -20.0 + -150.0  # -240
expected_margin = pnl / costs
@assert root_margin ≈ expected_margin
println("  ✅ derive_ratio(:pnl, :costs) = $(round(root_margin, digits=4))")

# Identity laws
attrib_id = identity(attrib_schema)
@assert combine(attrib_id, root(attrib_tray)) == root(attrib_tray)
@assert combine(root(attrib_tray), attrib_id) == root(attrib_tray)
println("  ✅ Identity laws hold on root")

println()
println("═══ POC PASSED — all assertions hold ═══")
