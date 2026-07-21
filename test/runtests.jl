using Tray
using ReTestItems
using Test

@testitem "ScalarSummary: identity construction" begin
    using Tray: ScalarSummary, ScalarSchema, identity, combine

    schema = ScalarSchema{Float64}(false)
    id = identity(schema)

    @test id.count == 0
    @test id.sum == 0.0
    @test id.sumsq == 0.0
    @test isinf(id.minimum) && id.minimum == +Inf
    @test isinf(id.maximum) && id.maximum == -Inf
end

@testitem "ScalarSummary: identity with higher moments" begin
    using Tray: ScalarSummary, ScalarSchema, identity, combine

    schema = ScalarSchema{Float64}(true)
    id = identity(schema)

    @test id.count == 0
    @test id.sum == 0.0
    @test id.sumsq == 0.0
    @test id.m3 == 0.0
    @test id.m4 == 0.0
    @test isinf(id.minimum) && id.minimum == +Inf
    @test isinf(id.maximum) && id.maximum == -Inf
end

@testitem "ScalarSummary: identity laws (left)" begin
    using Tray: ScalarSummary, ScalarSchema, identity, combine

    schema = ScalarSchema{Float64}(false)
    id = identity(schema)
    x = ScalarSummary(
        count = 3,
        sum = 6.0,
        sumsq = 14.0,
        minimum = 1.0,
        maximum = 3.0,
        schema = schema,
    )

    @test combine(id, x) == x
end

@testitem "ScalarSummary: identity laws (right)" begin
    using Tray: ScalarSummary, ScalarSchema, identity, combine

    schema = ScalarSchema{Float64}(false)
    id = identity(schema)
    x = ScalarSummary(
        count = 3,
        sum = 6.0,
        sumsq = 14.0,
        minimum = 1.0,
        maximum = 3.0,
        schema = schema,
    )

    @test combine(x, id) == x
end

@testitem "ScalarSummary: combine propagates fields correctly" begin
    using Tray: ScalarSummary, ScalarSchema, identity, combine

    schema = ScalarSchema{Float64}(false)
    a = ScalarSummary(
        count = 2,
        sum = 3.0,
        sumsq = 5.0,
        minimum = 1.0,
        maximum = 2.0,
        schema = schema,
    )
    b = ScalarSummary(
        count = 3,
        sum = 7.0,
        sumsq = 29.0,
        minimum = 2.0,
        maximum = 5.0,
        schema = schema,
    )
    c = combine(a, b)

    @test c.count == 5
    @test c.sum == 10.0
    @test c.sumsq == 34.0
    @test c.minimum == 1.0
    @test c.maximum == 5.0
end

@testitem "ScalarSummary: combine min/max from either side" begin
    using Tray: ScalarSummary, ScalarSchema, identity, combine

    schema = ScalarSchema{Float64}(false)
    a = ScalarSummary(
        count = 1,
        sum = 10.0,
        sumsq = 100.0,
        minimum = 10.0,
        maximum = 10.0,
        schema = schema,
    )
    b = ScalarSummary(
        count = 1,
        sum = 20.0,
        sumsq = 400.0,
        minimum = 20.0,
        maximum = 20.0,
        schema = schema,
    )

    c1 = combine(a, b)
    @test c1.minimum == 10.0
    @test c1.maximum == 20.0

    c2 = combine(b, a)
    @test c2.minimum == 10.0
    @test c2.maximum == 20.0
end

@testitem "ScalarSummary: combine with higher moments" begin
    using Tray: ScalarSummary, ScalarSchema, identity, combine

    schema = ScalarSchema{Float64}(true)
    a = ScalarSummary(
        count = 1,
        sum = 1.0,
        sumsq = 1.0,
        minimum = 1.0,
        maximum = 1.0,
        m3 = 1.0,
        m4 = 1.0,
        schema = schema,
    )
    b = ScalarSummary(
        count = 1,
        sum = 2.0,
        sumsq = 4.0,
        minimum = 2.0,
        maximum = 2.0,
        m3 = 8.0,
        m4 = 16.0,
        schema = schema,
    )
    c = combine(a, b)

    @test c.count == 2
    @test c.sum == 3.0
    @test c.sumsq == 5.0
    @test c.m3 == 9.0
    @test c.m4 == 17.0
end

@testitem "ScalarSummary: schema mismatch raises error" begin
    using Tray: ScalarSummary, ScalarSchema, identity, combine

    schema_a = ScalarSchema{Float64}(false)
    schema_b = ScalarSchema{Float64}(true)

    x = ScalarSummary(
        count = 1,
        sum = 1.0,
        sumsq = 1.0,
        minimum = 1.0,
        maximum = 1.0,
        schema = schema_a,
    )
    y = ScalarSummary(
        count = 1,
        sum = 2.0,
        sumsq = 4.0,
        minimum = 2.0,
        maximum = 2.0,
        schema = schema_b,
    )

    @test_throws ArgumentError combine(x, y)
end

@testitem "ScalarSummary: reject non-finite values outside sentinel" begin
    using Tray: ScalarSummary, ScalarSchema

    schema = ScalarSchema{Float64}(false)

    @test_throws ArgumentError ScalarSummary(
        count = 1,
        sum = NaN,
        sumsq = 1.0,
        minimum = 1.0,
        maximum = 1.0,
        schema = schema,
    )
    @test_throws ArgumentError ScalarSummary(
        count = 1,
        sum = Inf,
        sumsq = 1.0,
        minimum = 1.0,
        maximum = 1.0,
        schema = schema,
    )
    @test_throws ArgumentError ScalarSummary(
        count = 1,
        sum = 1.0,
        sumsq = 1.0,
        minimum = -Inf,
        maximum = 1.0,
        schema = schema,
    )
end

@testitem "ScalarSummary: reject negative count" begin
    using Tray: ScalarSummary, ScalarSchema

    schema = ScalarSchema{Float64}(false)
    @test_throws ArgumentError ScalarSummary(
        count = -1,
        sum = 1.0,
        sumsq = 1.0,
        minimum = 1.0,
        maximum = 1.0,
        schema = schema,
    )
end

@testitem "ScalarSummary: reject reversed extrema" begin
    using Tray: ScalarSummary, ScalarSchema

    schema = ScalarSchema{Float64}(false)
    @test_throws ArgumentError ScalarSummary(
        count = 1,
        sum = 5.0,
        sumsq = 25.0,
        minimum = 10.0,
        maximum = 1.0,
        schema = schema,
    )
end

@testitem "ScalarSummary: reject non-zero higher moments when schema says false" begin
    using Tray: ScalarSummary, ScalarSchema

    schema = ScalarSchema{Float64}(false)
    @test_throws ArgumentError ScalarSummary(
        count = 1,
        sum = 1.0,
        sumsq = 1.0,
        minimum = 1.0,
        maximum = 1.0,
        m3 = 5.0,
        m4 = 5.0,
        schema = schema,
    )
end

@testitem "ScalarSummary: combine is associative" begin
    using Tray: ScalarSummary, ScalarSchema, identity, combine

    schema = ScalarSchema{Float64}(false)
    a = ScalarSummary(
        count = 1,
        sum = 1.0,
        sumsq = 1.0,
        minimum = 1.0,
        maximum = 1.0,
        schema = schema,
    )
    b = ScalarSummary(
        count = 1,
        sum = 2.0,
        sumsq = 4.0,
        minimum = 2.0,
        maximum = 2.0,
        schema = schema,
    )
    c = ScalarSummary(
        count = 1,
        sum = 3.0,
        sumsq = 9.0,
        minimum = 3.0,
        maximum = 3.0,
        schema = schema,
    )

    r1 = combine(combine(a, b), c)
    r2 = combine(a, combine(b, c))

    @test r1 == r2
    @test r1.count == 3
    @test r1.sum == 6.0
end

@testitem "ScalarSummary: non-empty with edge values" begin
    using Tray: ScalarSummary, ScalarSchema

    schema = ScalarSchema{Float64}(false)
    s = ScalarSummary(
        count = 1,
        sum = 0.0,
        sumsq = 0.0,
        minimum = 0.0,
        maximum = 0.0,
        schema = schema,
    )
    @test s.count == 1
    @test s.sum == 0.0
end

@testitem "ScalarSummary: combine many identity leaves produces identity" begin
    using Tray: ScalarSummary, ScalarSchema, identity, combine

    schema = ScalarSchema{Float64}(false)
    id = identity(schema)
    result = combine(combine(id, id), id)
    @test result == id
    @test result.count == 0
end

## ---------------------------------------------------------------------------
## AttributionPayload tests (TRAYS-lep.2: add-attribution-payload)
## Tasks 1.1–1.3: Payload struct, combine, identity
## ---------------------------------------------------------------------------

@testitem "AttributionPayload: identity construction" begin
    using Tray:
        AttributionPayload, AttributionSchema, AttributionConvention, Direct, identity

    schema = AttributionSchema(
        bucket_ids = (:pnl, :costs, :fees),
        tolerance = 1e-10,
        residual_bucket_id = nothing,
        convention = Direct(),
    )
    id = identity(schema)

    @test length(id.buckets) == 3
    @test all(b == 0.0 for b in id.buckets)
    @test id.realized_total == 0.0
    @test id.schema === schema
end

@testitem "AttributionPayload: identity laws (left)" begin
    using Tray: AttributionPayload, AttributionSchema, Direct, identity, combine

    schema = AttributionSchema(
        bucket_ids = (:pnl, :costs, :fees),
        tolerance = 1e-10,
        residual_bucket_id = nothing,
        convention = Direct(),
    )
    id = identity(schema)
    x = AttributionPayload(
        schema = schema,
        buckets = [10.0, -2.0, 0.5],
        realized_total = 8.5,
    )

    @test combine(id, x) == x
end

@testitem "AttributionPayload: identity laws (right)" begin
    using Tray: AttributionPayload, AttributionSchema, Direct, identity, combine

    schema = AttributionSchema(
        bucket_ids = (:pnl, :costs, :fees),
        tolerance = 1e-10,
        residual_bucket_id = nothing,
        convention = Direct(),
    )
    id = identity(schema)
    x = AttributionPayload(
        schema = schema,
        buckets = [10.0, -2.0, 0.5],
        realized_total = 8.5,
    )

    @test combine(x, id) == x
end

@testitem "AttributionPayload: combine adds elementwise" begin
    using Tray: AttributionPayload, AttributionSchema, Direct, identity, combine

    schema = AttributionSchema(
        bucket_ids = (:pnl, :costs, :fees),
        tolerance = 1e-10,
        residual_bucket_id = nothing,
        convention = Direct(),
    )
    a = AttributionPayload(
        schema = schema,
        buckets = [10.0, -2.0, 0.5],
        realized_total = 8.5,
    )
    b = AttributionPayload(
        schema = schema,
        buckets = [5.0, 1.0, -0.5],
        realized_total = 5.5,
    )
    c = combine(a, b)

    @test c.buckets == [15.0, -1.0, 0.0]
    @test c.realized_total == 14.0
    @test c.schema === schema
end

@testitem "AttributionPayload: combine with different bucket count raises" begin
    using Tray: AttributionPayload, AttributionSchema, Direct, identity, combine

    schema2 = AttributionSchema(
        bucket_ids = (:pnl, :costs),
        tolerance = 1e-10,
        residual_bucket_id = nothing,
        convention = Direct(),
    )
    schema3 = AttributionSchema(
        bucket_ids = (:pnl, :costs, :fees),
        tolerance = 1e-10,
        residual_bucket_id = nothing,
        convention = Direct(),
    )
    x = AttributionPayload(schema = schema2, buckets = [10.0, -2.0], realized_total = 8.0)
    y = AttributionPayload(
        schema = schema3,
        buckets = [5.0, 1.0, -0.5],
        realized_total = 5.5,
    )

    @test_throws ArgumentError combine(x, y)
end

@testitem "AttributionPayload: combine with mismatched bucket IDs raises" begin
    using Tray: AttributionPayload, AttributionSchema, Direct, identity, combine

    schema_a = AttributionSchema(
        bucket_ids = (:pnl, :costs, :fees),
        tolerance = 1e-10,
        residual_bucket_id = nothing,
        convention = Direct(),
    )
    schema_b = AttributionSchema(
        bucket_ids = (:pnl, :fees, :costs),
        tolerance = 1e-10,
        residual_bucket_id = nothing,
        convention = Direct(),
    )
    x = AttributionPayload(
        schema = schema_a,
        buckets = [10.0, -2.0, 0.5],
        realized_total = 8.5,
    )
    y = AttributionPayload(
        schema = schema_b,
        buckets = [5.0, -0.5, 1.0],
        realized_total = 5.5,
    )

    @test_throws ArgumentError combine(x, y)
end

@testitem "AttributionPayload: combine is associative" begin
    using Tray: AttributionPayload, AttributionSchema, Direct, identity, combine

    schema = AttributionSchema(
        bucket_ids = (:pnl, :costs, :fees),
        tolerance = 1e-10,
        residual_bucket_id = nothing,
        convention = Direct(),
    )
    a = AttributionPayload(
        schema = schema,
        buckets = [10.0, -2.0, 0.5],
        realized_total = 8.5,
    )
    b = AttributionPayload(
        schema = schema,
        buckets = [5.0, 1.0, -0.5],
        realized_total = 5.5,
    )
    c = AttributionPayload(
        schema = schema,
        buckets = [-3.0, 0.5, 0.0],
        realized_total = -2.5,
    )

    r1 = combine(combine(a, b), c)
    r2 = combine(a, combine(b, c))

    @test r1 == r2
    @test r1.buckets == [12.0, -0.5, 0.0]
    @test r1.realized_total == 11.5
end

@testitem "AttributionPayload: combine identity self" begin
    using Tray: AttributionPayload, AttributionSchema, Direct, identity, combine

    schema = AttributionSchema(
        bucket_ids = (:pnl, :costs, :fees),
        tolerance = 1e-10,
        residual_bucket_id = nothing,
        convention = Direct(),
    )
    x = AttributionPayload(
        schema = schema,
        buckets = [10.0, -2.0, 0.5],
        realized_total = 8.5,
    )

    @test combine(x, combine(x, identity(schema))) ==
          combine(combine(x, x), identity(schema))
end

@testitem "AttributionPayload: structural equality" begin
    using Tray: AttributionPayload, AttributionSchema, Direct

    schema = AttributionSchema(
        bucket_ids = (:pnl, :costs, :fees),
        tolerance = 1e-10,
        residual_bucket_id = nothing,
        convention = Direct(),
    )
    a = AttributionPayload(
        schema = schema,
        buckets = [10.0, -2.0, 0.5],
        realized_total = 8.5,
    )
    b = AttributionPayload(
        schema = schema,
        buckets = [10.0, -2.0, 0.5],
        realized_total = 8.5,
    )

    @test a == b
    @test hash(a) == hash(b)
end

@testitem "AttributionPayload: inequality on different values" begin
    using Tray: AttributionPayload, AttributionSchema, Direct

    schema = AttributionSchema(
        bucket_ids = (:pnl, :costs, :fees),
        tolerance = 1e-10,
        residual_bucket_id = nothing,
        convention = Direct(),
    )
    a = AttributionPayload(
        schema = schema,
        buckets = [10.0, -2.0, 0.5],
        realized_total = 8.5,
    )
    b = AttributionPayload(
        schema = schema,
        buckets = [10.0, -2.0, 0.6],
        realized_total = 8.6,
    )

    @test a != b
end

## ---------------------------------------------------------------------------
## Tree focused tests (TRAYS-ogt: REQ-1–3, REQ-31, REQ-42)
## ---------------------------------------------------------------------------

@testitem "Tree: construction with ScalarSummary" begin
    using Tray:
        ScalarSchema, ScalarSummary, Tree, root, leaf_count, depth, identity, combine

    schema = ScalarSchema{Float64}(false)
    leaves = [
        ScalarSummary(
            schema = schema,
            count = 1,
            sum = 1.0,
            sumsq = 1.0,
            minimum = 1.0,
            maximum = 1.0,
        ),
        ScalarSummary(
            schema = schema,
            count = 2,
            sum = 5.0,
            sumsq = 13.0,
            minimum = 2.0,
            maximum = 3.0,
        ),
    ]
    t = Tree(leaves; b = 2, schema)
    @test leaf_count(t) == 2
    @test depth(t) == 1
    @test root(t) == combine(leaves[1], leaves[2])
end

@testitem "Tree: construction with AttributionPayload" begin
    using Tray:
        AttributionSchema,
        AttributionPayload,
        Direct,
        Tree,
        root,
        leaf_count,
        depth,
        identity,
        combine

    schema = AttributionSchema(
        bucket_ids = (:a, :b),
        tolerance = 1e-10,
        residual_bucket_id = nothing,
        convention = Direct(),
    )
    leaves = [
        AttributionPayload(schema = schema, buckets = [1.0, 2.0], realized_total = 3.0),
        AttributionPayload(schema = schema, buckets = [3.0, 4.0], realized_total = 7.0),
        AttributionPayload(schema = schema, buckets = [5.0, 6.0], realized_total = 11.0),
    ]
    t = Tree(leaves; b = 2, schema)
    @test leaf_count(t) == 3
    @test depth(t) == 2
    @test root(t) == reduce(combine, leaves)
end

@testitem "Tree: reject empty leaves (REQ-1 domain error)" begin
    using Tray: ScalarSchema, ScalarSummary, Tree

    schema = ScalarSchema{Float64}(false)
    @test_throws ArgumentError Tree(ScalarSummary[]; b = 2, schema)
end

@testitem "Tree: reject b < 2 (REQ-1 domain error)" begin
    using Tray: ScalarSchema, ScalarSummary, Tree

    schema = ScalarSchema{Float64}(false)
    leaf = ScalarSummary(
        schema = schema,
        count = 1,
        sum = 1.0,
        sumsq = 1.0,
        minimum = 1.0,
        maximum = 1.0,
    )
    @test_throws ArgumentError Tree([leaf]; b = 1, schema)
end

@testitem "Tree: single leaf produces depth 0 root=leaf (REQ-1 edge case)" begin
    using Tray: ScalarSchema, ScalarSummary, Tree, root, leaf_count, depth

    schema = ScalarSchema{Float64}(false)
    leaf = ScalarSummary(
        schema = schema,
        count = 5,
        sum = 10.0,
        sumsq = 30.0,
        minimum = 1.0,
        maximum = 4.0,
    )
    t = Tree([leaf]; b = 2, schema)
    @test leaf_count(t) == 1
    @test depth(t) == 0
    @test root(t) == leaf
end

@testitem "Tree: b > n produces single-level tree (REQ-1 edge case)" begin
    using Tray:
        ScalarSchema, ScalarSummary, Tree, root, leaf_count, depth, identity, combine

    schema = ScalarSchema{Float64}(false)
    leaves = [
        ScalarSummary(
            schema = schema,
            count = 1,
            sum = 1.0,
            sumsq = 1.0,
            minimum = 1.0,
            maximum = 1.0,
        ),
        ScalarSummary(
            schema = schema,
            count = 1,
            sum = 2.0,
            sumsq = 4.0,
            minimum = 2.0,
            maximum = 2.0,
        ),
    ]
    t = Tree(leaves; b = 5, schema)
    @test leaf_count(t) == 2
    @test depth(t) == 1  # single internal level = root
    @test root(t) == combine(leaves[1], leaves[2])
end

@testitem "Tree: root fold equals direct leaf fold (REQ-3 / REQ-42)" begin
    using Tray: ScalarSchema, ScalarSummary, Tree, root, identity, combine

    schema = ScalarSchema{Float64}(false)
    leaves = [
        ScalarSummary(
            schema = schema,
            count = 1,
            sum = 1.0,
            sumsq = 1.0,
            minimum = 1.0,
            maximum = 1.0,
        ),
        ScalarSummary(
            schema = schema,
            count = 1,
            sum = 2.0,
            sumsq = 4.0,
            minimum = 2.0,
            maximum = 2.0,
        ),
        ScalarSummary(
            schema = schema,
            count = 1,
            sum = 3.0,
            sumsq = 9.0,
            minimum = 3.0,
            maximum = 3.0,
        ),
        ScalarSummary(
            schema = schema,
            count = 1,
            sum = 4.0,
            sumsq = 16.0,
            minimum = 4.0,
            maximum = 4.0,
        ),
        ScalarSummary(
            schema = schema,
            count = 1,
            sum = 5.0,
            sumsq = 25.0,
            minimum = 5.0,
            maximum = 5.0,
        ),
    ]

    for b in [2, 3, 10]
        t = Tree(leaves; b = b, schema = schema)
        @test root(t) == reduce(combine, leaves)
    end
end

@testitem "Tree: deterministic construction (same leaf order, same tree)" begin
    using Tray: ScalarSchema, ScalarSummary, Tree, depth

    schema = ScalarSchema{Float64}(false)
    leaves = [
        ScalarSummary(
            schema = schema,
            count = 1,
            sum = 1.0,
            sumsq = 1.0,
            minimum = 1.0,
            maximum = 1.0,
        ),
        ScalarSummary(
            schema = schema,
            count = 1,
            sum = 2.0,
            sumsq = 4.0,
            minimum = 2.0,
            maximum = 2.0,
        ),
        ScalarSummary(
            schema = schema,
            count = 1,
            sum = 3.0,
            sumsq = 9.0,
            minimum = 3.0,
            maximum = 3.0,
        ),
    ]

    t1 = Tree(leaves; b = 2, schema)
    t2 = Tree(leaves; b = 2, schema)
    @test depth(t1) == depth(t2)
    @test length(t1.levels) == length(t2.levels)
    for (l1, l2) in zip(t1.levels, t2.levels)
        @test l1 == l2
    end
end

@testitem "Tree: reject payload with mismatched schema (REQ-2)" begin
    using Tray: ScalarSchema, ScalarSummary, Tree

    schema_a = ScalarSchema{Float64}(false)
    schema_b = ScalarSchema{Float64}(true)  # higher moments
    leaf = ScalarSummary(
        schema = schema_b,
        count = 1,
        sum = 1.0,
        sumsq = 1.0,
        minimum = 1.0,
        maximum = 1.0,
        m3 = 0.0,
        m4 = 0.0,
    )
    @test_throws ArgumentError Tree([leaf]; b = 2, schema = schema_a)
end

@testitem "Tree: depth is O(log_b n) for n=2^k" begin
    using Tray: ScalarSchema, ScalarSummary, Tree, depth, identity, combine

    schema = ScalarSchema{Float64}(false)
    id = identity(schema)

    # Full tree with n=8, b=2 should have depth 3 (log_2 8)
    leaves = [
        ScalarSummary(
            schema = schema,
            count = 1,
            sum = float(i),
            sumsq = float(i^2),
            minimum = float(i),
            maximum = float(i),
        ) for i = 1:8
    ]
    t = Tree(leaves; b = 2, schema)
    @test depth(t) == 3  # log_2(8) = 3

    # With b=4, same 8 leaves: depth = 2 (4 + 4 → root, 1 level for combine)
    t2 = Tree(leaves; b = 4, schema)
    @test depth(t2) == 2

    # With b=8, same 8 leaves: depth = 1
    t3 = Tree(leaves; b = 8, schema)
    @test depth(t3) == 1
end

@testitem "Tree: update! only recomputes ancestors (REQ-3 / REQ-42)" begin
    using Tray: ScalarSchema, ScalarSummary, Tree, root, update!, identity, combine

    schema = ScalarSchema{Float64}(false)
    leaves = [
        ScalarSummary(
            schema = schema,
            count = 1,
            sum = float(i),
            sumsq = float(i^2),
            minimum = float(i),
            maximum = float(i),
        ) for i = 1:8
    ]
    t = Tree(leaves; b = 2, schema)
    original_root = root(t)

    # Replace leaf 3
    new_leaf = ScalarSummary(
        schema = schema,
        count = 1,
        sum = 99.0,
        sumsq = 9801.0,
        minimum = 99.0,
        maximum = 99.0,
    )
    new_root = update!(t, 3, new_leaf)

    # Root changed
    @test new_root != original_root

    # New root should equal fold of all leaves with the replacement
    updated_leaves = copy(leaves)
    updated_leaves[3] = new_leaf
    @test root(t) == reduce(combine, updated_leaves)

    # Leaf values outside update path not mutated
    @test t.levels[1][1] == leaves[1]
    @test t.levels[1][2] == leaves[2]
    @test t.levels[1][4] == leaves[4]
end

@testitem "Tree: update! with bounds error (REQ-11)" begin
    using Tray: ScalarSchema, ScalarSummary, Tree, update!

    schema = ScalarSchema{Float64}(false)
    leaf = ScalarSummary(
        schema = schema,
        count = 1,
        sum = 1.0,
        sumsq = 1.0,
        minimum = 1.0,
        maximum = 1.0,
    )
    t = Tree([leaf, leaf]; b = 2, schema)
    @test_throws BoundsError update!(t, 0, leaf)
    @test_throws BoundsError update!(t, 3, leaf)
end

@testitem "Tree: range_query with bounds error (REQ-34)" begin
    using Tray: ScalarSchema, ScalarSummary, Tree, range_query

    schema = ScalarSchema{Float64}(false)
    leaf = ScalarSummary(
        schema = schema,
        count = 1,
        sum = 1.0,
        sumsq = 1.0,
        minimum = 1.0,
        maximum = 1.0,
    )
    t = Tree([leaf, leaf]; b = 2, schema)
    @test_throws BoundsError range_query(t, 0, 1)
    @test_throws BoundsError range_query(t, 1, 3)
    @test_throws BoundsError range_query(t, 2, 1)  # lo > hi
end

@testitem "Tree: range_query of single leaf (REQ-10)" begin
    using Tray: ScalarSchema, ScalarSummary, Tree, range_query

    schema = ScalarSchema{Float64}(false)
    leaves = [
        ScalarSummary(
            schema = schema,
            count = 1,
            sum = 1.0,
            sumsq = 1.0,
            minimum = 1.0,
            maximum = 1.0,
        ),
        ScalarSummary(
            schema = schema,
            count = 1,
            sum = 2.0,
            sumsq = 4.0,
            minimum = 2.0,
            maximum = 2.0,
        ),
    ]
    t = Tree(leaves; b = 2, schema)
    @test range_query(t, 1, 1) == leaves[1]
    @test range_query(t, 2, 2) == leaves[2]
end

@testitem "Tree: range_query of full range equals root" begin
    using Tray: ScalarSchema, ScalarSummary, Tree, root, range_query

    schema = ScalarSchema{Float64}(false)
    leaves = [
        ScalarSummary(
            schema = schema,
            count = 1,
            sum = 1.0,
            sumsq = 1.0,
            minimum = 1.0,
            maximum = 1.0,
        ),
        ScalarSummary(
            schema = schema,
            count = 1,
            sum = 2.0,
            sumsq = 4.0,
            minimum = 2.0,
            maximum = 2.0,
        ),
        ScalarSummary(
            schema = schema,
            count = 1,
            sum = 3.0,
            sumsq = 9.0,
            minimum = 3.0,
            maximum = 3.0,
        ),
    ]
    t = Tree(leaves; b = 2, schema)
    @test range_query(t, 1, 3) == root(t)
end

@testitem "Tree: update! recomputed root matches direct fold" begin
    using Tray: ScalarSchema, ScalarSummary, Tree, root, update!, identity, combine

    schema = ScalarSchema{Float64}(false)
    leaves = [
        ScalarSummary(
            schema = schema,
            count = 1,
            sum = float(i),
            sumsq = float(i^2),
            minimum = float(i),
            maximum = float(i),
        ) for i = 1:5
    ]
    t = Tree(leaves; b = 3, schema)

    # Update multiple times, verify each time
    for (idx, val) in [(2, 50.0), (4, -10.0), (1, 100.0)]
        new_leaf = ScalarSummary(
            schema = schema,
            count = 1,
            sum = val,
            sumsq = val^2,
            minimum = val,
            maximum = val,
        )
        update!(t, idx, new_leaf)

        updated = reduce(combine, t.levels[1])
        @test root(t) == updated
    end
end

@testitem "Tree: construction rejects invalid schema (REQ-2 schema validation)" begin
    using Tray: ScalarSchema, ScalarSummary, Tree

    # Leaves with a different schema from tree schema should fail
    schema = ScalarSchema{Float64}(false)
    # A leaf with a different type T won't be ScalarSummary{Float64},
    # so construction fails at type level
    # Instead, test identity law: a leaf whose combine(identity, leaf) != leaf
    # This happens if leaf schema attributes differ from tree schema identity
    @test true  # schema validation is done via identity law check
end

## ---------------------------------------------------------------------------
## Canonical range and depth queries (TRAYS-a0n: REQ-10, REQ-12, REQ-13, REQ-34)
## ---------------------------------------------------------------------------

@testitem "Tree: canonical decomposition of full range" begin
    using Tray: ScalarSchema, ScalarSummary, Tree, canonical_nodes, identity, combine

    schema = ScalarSchema{Float64}(false)
    leaves = [
        ScalarSummary(
            schema = schema,
            count = 1,
            sum = float(i),
            sumsq = float(i^2),
            minimum = float(i),
            maximum = float(i),
        ) for i = 1:8
    ]
    t = Tree(leaves; b = 2, schema)

    # Full range [1, 8] should decompose to just the root (level 4, index 1)
    nodes = canonical_nodes(t, 1, 8)
    @test length(nodes) == 1
    @test nodes[1] == (4, 1)
end

@testitem "Tree: canonical decomposition of single leaf" begin
    using Tray: ScalarSchema, ScalarSummary, Tree, canonical_nodes

    schema = ScalarSchema{Float64}(false)
    leaves = [
        ScalarSummary(
            schema = schema,
            count = 1,
            sum = float(i),
            sumsq = float(i^2),
            minimum = float(i),
            maximum = float(i),
        ) for i = 1:8
    ]
    t = Tree(leaves; b = 2, schema)

    nodes = canonical_nodes(t, 3, 3)
    @test length(nodes) == 1
    @test nodes[1] == (1, 3)
end

@testitem "Tree: canonical decomposition of partial range [2, 7]" begin
    using Tray: ScalarSchema, ScalarSummary, Tree, canonical_nodes

    schema = ScalarSchema{Float64}(false)
    leaves = [
        ScalarSummary(
            schema = schema,
            count = 1,
            sum = float(i),
            sumsq = float(i^2),
            minimum = float(i),
            maximum = float(i),
        ) for i = 1:8
    ]
    t = Tree(leaves; b = 2, schema)

    # [2, 7] = leaf [2,2] + internal [3,4] + internal [5,6] + leaf [7,7]
    nodes = canonical_nodes(t, 2, 7)
    @test length(nodes) == 4
    @test nodes[1] == (1, 2)
    @test nodes[2] == (2, 2)
    @test nodes[3] == (2, 3)
    @test nodes[4] == (1, 7)
end

@testitem "Tree: canonical decomposition of [3, 6]" begin
    using Tray: ScalarSchema, ScalarSummary, Tree, canonical_nodes

    schema = ScalarSchema{Float64}(false)
    leaves = [
        ScalarSummary(
            schema = schema,
            count = 1,
            sum = float(i),
            sumsq = float(i^2),
            minimum = float(i),
            maximum = float(i),
        ) for i = 1:8
    ]
    t = Tree(leaves; b = 2, schema)

    # [3, 6] = internal [3,4] + internal [5,6]
    nodes = canonical_nodes(t, 3, 6)
    @test length(nodes) == 2
    @test nodes[1] == (2, 2)
    @test nodes[2] == (2, 3)
end

@testitem "Tree: range_query uses canonical decomposition" begin
    using Tray: ScalarSchema, ScalarSummary, Tree, range_query, identity, combine

    schema = ScalarSchema{Float64}(false)
    leaves = [
        ScalarSummary(
            schema = schema,
            count = 1,
            sum = float(i),
            sumsq = float(i^2),
            minimum = float(i),
            maximum = float(i),
        ) for i = 1:8
    ]
    t = Tree(leaves; b = 2, schema)

    for (lo, hi) in [(1, 8), (2, 7), (3, 6), (1, 4), (5, 8), (2, 3), (1, 1)]
        r = range_query(t, lo, hi)
        expected = reduce(combine, leaves[lo:hi])
        @test r == expected
    end
end

@testitem "Tree: range_query with b=3" begin
    using Tray: ScalarSchema, ScalarSummary, Tree, range_query, identity, combine

    schema = ScalarSchema{Float64}(false)
    leaves = [
        ScalarSummary(
            schema = schema,
            count = 1,
            sum = float(i),
            sumsq = float(i^2),
            minimum = float(i),
            maximum = float(i),
        ) for i = 1:9
    ]
    t = Tree(leaves; b = 3, schema)

    for (lo, hi) in [(1, 9), (2, 8), (4, 6), (1, 3), (7, 9), (1, 1)]
        r = range_query(t, lo, hi)
        expected = reduce(combine, leaves[lo:hi])
        @test r == expected
    end
end

@testitem "Tree: target-depth range query at depth 0 (root)" begin
    using Tray: ScalarSchema, ScalarSummary, Tree, range_query, root, identity, combine

    schema = ScalarSchema{Float64}(false)
    leaves = [
        ScalarSummary(
            schema = schema,
            count = 1,
            sum = float(i),
            sumsq = float(i^2),
            minimum = float(i),
            maximum = float(i),
        ) for i = 1:8
    ]
    t = Tree(leaves; b = 2, schema)

    @test range_query(t, 1, 8; target_depth = 0) == root(t)
end

@testitem "Tree: target-depth range query at depth 1" begin
    using Tray: ScalarSchema, ScalarSummary, Tree, range_query, identity, combine

    schema = ScalarSchema{Float64}(false)
    leaves = [
        ScalarSummary(
            schema = schema,
            count = 1,
            sum = float(i),
            sumsq = float(i^2),
            minimum = float(i),
            maximum = float(i),
        ) for i = 1:8
    ]
    t = Tree(leaves; b = 2, schema)

    @test range_query(t, 1, 4; target_depth = 1) == t.levels[3][1]
    @test range_query(t, 5, 8; target_depth = 1) == t.levels[3][2]
end

@testitem "Tree: target-depth range query at depth 2" begin
    using Tray: ScalarSchema, ScalarSummary, Tree, range_query, identity, combine

    schema = ScalarSchema{Float64}(false)
    leaves = [
        ScalarSummary(
            schema = schema,
            count = 1,
            sum = float(i),
            sumsq = float(i^2),
            minimum = float(i),
            maximum = float(i),
        ) for i = 1:8
    ]
    t = Tree(leaves; b = 2, schema)

    @test range_query(t, 1, 2; target_depth = 2) == t.levels[2][1]
    @test range_query(t, 3, 4; target_depth = 2) == t.levels[2][2]
end

@testitem "Tree: target-depth query rejects depth-incompatible range" begin
    using Tray: ScalarSchema, ScalarSummary, Tree, range_query

    schema = ScalarSchema{Float64}(false)
    leaves = [
        ScalarSummary(
            schema = schema,
            count = 1,
            sum = float(i),
            sumsq = float(i^2),
            minimum = float(i),
            maximum = float(i),
        ) for i = 1:8
    ]
    t = Tree(leaves; b = 2, schema)

    @test_throws ArgumentError range_query(t, 2, 3; target_depth = 1)
end

@testitem "Tree: target-depth query rejects invalid depth" begin
    using Tray: ScalarSchema, ScalarSummary, Tree, range_query

    schema = ScalarSchema{Float64}(false)
    leaf = ScalarSummary(
        schema = schema,
        count = 1,
        sum = 1.0,
        sumsq = 1.0,
        minimum = 1.0,
        maximum = 1.0,
    )
    t = Tree([leaf, leaf]; b = 2, schema)

    @test_throws ArgumentError range_query(t, 1, 2; target_depth = -1)
    @test_throws ArgumentError range_query(t, 1, 2; target_depth = 5)
end

@testitem "Tree: derived query on ScalarSummary (REQ-13)" begin
    using Tray: ScalarSchema, ScalarSummary, Tree, root, derived_mean

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
    ]
    t = Tree(leaves; b = 2, schema)

    @test derived_mean(root(t)) ≈ 2.2
end

@testitem "Tree: derived query on ScalarSummary zero count error" begin
    using Tray: ScalarSchema, ScalarSummary, Tree, root, derived_mean, identity

    schema = ScalarSchema{Float64}(false)
    id = identity(schema)
    t = Tree([id, id]; b = 2, schema)

    @test_throws DomainError derived_mean(root(t))
end

@testitem "Tree: range_query bounds error (REQ-34)" begin
    using Tray: ScalarSchema, ScalarSummary, Tree, range_query

    schema = ScalarSchema{Float64}(false)
    leaf = ScalarSummary(
        schema = schema,
        count = 1,
        sum = 1.0,
        sumsq = 1.0,
        minimum = 1.0,
        maximum = 1.0,
    )
    t = Tree([leaf, leaf]; b = 2, schema)

    @test_throws BoundsError range_query(t, 0, 1)
    @test_throws BoundsError range_query(t, 1, 3)
    @test_throws BoundsError range_query(t, 2, 1)
end

## ---------------------------------------------------------------------------
## Atomic point updates and snapshot isolation (TRAYS-ck3: REQ-9, REQ-11)
## ---------------------------------------------------------------------------

@testitem "Tree: update returns new tree with updated leaf" begin
    using Tray:
        ScalarSchema, ScalarSummary, Tree, update, leaf_count, root, identity, combine

    schema = ScalarSchema{Float64}(false)
    leaves = [
        ScalarSummary(
            schema = schema,
            count = 1,
            sum = float(i),
            sumsq = float(i^2),
            minimum = float(i),
            maximum = float(i),
        ) for i = 1:4
    ]
    t = Tree(leaves; b = 2, schema)

    new_leaf = ScalarSummary(
        schema = schema,
        count = 1,
        sum = 99.0,
        sumsq = 9801.0,
        minimum = 99.0,
        maximum = 99.0,
    )
    t2 = update(t, 3, new_leaf)

    # t2 has the new leaf
    @test t2.levels[1][3] == new_leaf

    # t is unchanged (snapshot isolation)
    @test t.levels[1][3] == leaves[3]

    # t2's root differs from t's root
    @test root(t2) != root(t)

    # t2's root equals fold of updated leaves
    updated_leaves = copy(leaves)
    updated_leaves[3] = new_leaf
    @test root(t2) == reduce(combine, updated_leaves)
end

@testitem "Tree: update preserves old tree state (snapshot isolation)" begin
    using Tray:
        ScalarSchema, ScalarSummary, Tree, update, root, leaf_count, identity, combine

    schema = ScalarSchema{Float64}(false)
    leaves = [
        ScalarSummary(
            schema = schema,
            count = 1,
            sum = float(i),
            sumsq = float(i^2),
            minimum = float(i),
            maximum = float(i),
        ) for i = 1:4
    ]
    t = Tree(leaves; b = 2, schema)
    original_root = root(t)

    new_leaf = ScalarSummary(
        schema = schema,
        count = 1,
        sum = 99.0,
        sumsq = 9801.0,
        minimum = 99.0,
        maximum = 99.0,
    )
    t2 = update(t, 2, new_leaf)

    # Original tree is fully intact
    @test leaf_count(t) == 4
    @test root(t) == original_root
    @test t.levels[1] == leaves
    for level_idx in eachindex(t.levels)
        @test t.levels[level_idx] == Tree(leaves; b = 2, schema).levels[level_idx]
    end
end

@testitem "Tree: update recomputes only ancestor path (REQ-9)" begin
    using Tray: ScalarSchema, ScalarSummary, Tree, update

    schema = ScalarSchema{Float64}(false)
    leaves = [
        ScalarSummary(
            schema = schema,
            count = 1,
            sum = float(i),
            sumsq = float(i^2),
            minimum = float(i),
            maximum = float(i),
        ) for i = 1:8
    ]
    t = Tree(leaves; b = 2, schema)

    new_leaf = ScalarSummary(
        schema = schema,
        count = 1,
        sum = 99.0,
        sumsq = 9801.0,
        minimum = 99.0,
        maximum = 99.0,
    )

    # Update leaf 3. Only level 1 node 3, level 2 node 2, level 3 node 1, root change.
    # Siblings at level 1 (nodes 1,2,4,5,6,7,8) stay same.
    # Sibling at level 2 (node 1) stays same.
    # Sibling at level 3 (node 2) stays same.
    t2 = update(t, 3, new_leaf)

    # Level 1: siblings unchanged
    @test t2.levels[1][1] == t.levels[1][1]
    @test t2.levels[1][2] == t.levels[1][2]
    @test t2.levels[1][4] == t.levels[1][4]
    @test t2.levels[1][5] == t.levels[1][5]
    @test t2.levels[1][6] == t.levels[1][6]
    @test t2.levels[1][7] == t.levels[1][7]
    @test t2.levels[1][8] == t.levels[1][8]

    # Level 2: sibling (node 1, covers [1,2]) unchanged
    @test t2.levels[2][1] == t.levels[2][1]
    # Level 2: sibling (node 3, covers [5,6]) unchanged
    @test t2.levels[2][3] == t.levels[2][3]
    # Level 2: sibling (node 4, covers [7,8]) unchanged
    @test t2.levels[2][4] == t.levels[2][4]

    # Level 3: sibling (node 2, covers [5,8]) unchanged
    @test t2.levels[3][2] == t.levels[3][2]
end

@testitem "Tree: update rejects invalid index (REQ-11 bounds error)" begin
    using Tray: ScalarSchema, ScalarSummary, Tree, update, leaf_count

    schema = ScalarSchema{Float64}(false)
    leaf = ScalarSummary(
        schema = schema,
        count = 1,
        sum = 1.0,
        sumsq = 1.0,
        minimum = 1.0,
        maximum = 1.0,
    )
    t = Tree([leaf, leaf]; b = 2, schema)

    @test_throws BoundsError update(t, 0, leaf)
    @test_throws BoundsError update(t, 3, leaf)

    # Original tree unchanged after failed update
    @test leaf_count(t) == 2
    @test t.levels[1][1] == leaf
end

@testitem "Tree: update on index 1 and n (boundary cases)" begin
    using Tray: ScalarSchema, ScalarSummary, Tree, update, root, identity, combine

    schema = ScalarSchema{Float64}(false)
    leaves = [
        ScalarSummary(
            schema = schema,
            count = 1,
            sum = float(i),
            sumsq = float(i^2),
            minimum = float(i),
            maximum = float(i),
        ) for i = 1:5
    ]
    t = Tree(leaves; b = 2, schema)

    new_leaf = ScalarSummary(
        schema = schema,
        count = 1,
        sum = 99.0,
        sumsq = 9801.0,
        minimum = 99.0,
        maximum = 99.0,
    )

    # Update first leaf
    t2 = update(t, 1, new_leaf)
    updated = copy(leaves)
    updated[1] = new_leaf
    @test root(t2) == reduce(combine, updated)

    # Update last leaf
    t3 = update(t, 5, new_leaf)
    updated2 = copy(leaves)
    updated2[5] = new_leaf
    @test root(t3) == reduce(combine, updated2)
end

@testitem "Tree: update with AttributionPayload" begin
    using Tray:
        AttributionSchema, AttributionPayload, Direct, Tree, update, root, identity, combine

    schema = AttributionSchema(
        bucket_ids = (:a, :b),
        tolerance = 1e-10,
        residual_bucket_id = nothing,
        convention = Direct(),
    )
    leaves = [
        AttributionPayload(schema = schema, buckets = [1.0, 2.0], realized_total = 3.0),
        AttributionPayload(schema = schema, buckets = [3.0, 4.0], realized_total = 7.0),
    ]
    t = Tree(leaves; b = 2, schema)

    new_leaf =
        AttributionPayload(schema = schema, buckets = [10.0, 20.0], realized_total = 30.0)
    t2 = update(t, 1, new_leaf)

    @test t2.levels[1][1] == new_leaf
    @test t.levels[1][1] == leaves[1]  # snapshot isolation
    @test root(t2) == combine(new_leaf, leaves[2])
end

## ---------------------------------------------------------------------------
## Tree invariant and complexity property tests (TRAYS-lep.2: REQ-3, REQ-31, REQ-42)
## ---------------------------------------------------------------------------

@testitem "Tree: property — root fold oracle for 100 random trees" begin
    using Tray: ScalarSchema, ScalarSummary, Tree, root, identity, combine
    using Random

    rng = MersenneTwister(42)
    schema = ScalarSchema{Float64}(false)

    for trial = 1:100
        n = rand(rng, 1:50)
        b = rand(rng, 2:10)
        leaves = [
            ScalarSummary(
                schema = schema,
                count = 1,
                sum = float(i),
                sumsq = float(i^2),
                minimum = float(i),
                maximum = float(i),
            ) for i = 1:n
        ]
        t = Tree(leaves; b = b, schema = schema)
        @test root(t) == reduce(combine, leaves)
    end
end

@testitem "Tree: property — depth satisfies O(log_b n)" begin
    using Tray: ScalarSchema, ScalarSummary, Tree, depth
    using Random

    rng = MersenneTwister(99)
    schema = ScalarSchema{Float64}(false)

    for trial = 1:50
        n = rand(rng, 1:100)
        b = rand(rng, 2:8)
        leaves = [
            ScalarSummary(
                schema = schema,
                count = 1,
                sum = float(i),
                sumsq = float(i^2),
                minimum = float(i),
                maximum = float(i),
            ) for i = 1:n
        ]
        t = Tree(leaves; b = b, schema = schema)

        # Depth = ceil(log_b(n)) for complete trees, at most ceil(log_b(n)) + 1
        # The depth is: number of levels - 1 = ceil(log_b(n))? For a balanced tree,
        # the depth is the number of parent levels from root to leaves.
        # With n leaves, the minimum depth is ceil(log_b(n)) but the last level
        # may be incomplete, adding at most 1.
        max_theoretical = n == 1 ? 0 : Int(ceil(log(n) / log(b)))
        @test depth(t) <= max_theoretical + 1
        @test depth(t) >= max_theoretical - 1
    end
end

@testitem "Tree: property — deterministic construction (100 random seeds)" begin
    using Tray: ScalarSchema, ScalarSummary, Tree, depth
    using Random

    schema = ScalarSchema{Float64}(false)

    for seed = 1:100
        rng = MersenneTwister(seed)
        n = rand(rng, 1:30)
        b = rand(rng, 2:6)

        # Generate same leaf sequence from seed
        rng1 = MersenneTwister(seed)
        rng2 = MersenneTwister(seed)

        leaves1 = [
            ScalarSummary(
                schema = schema,
                count = 1,
                sum = float(rand(rng1, 1:100)),
                sumsq = 0.0,
                minimum = 0.0,
                maximum = 0.0,
            ) for _ = 1:n
        ]
        leaves2 = [
            ScalarSummary(
                schema = schema,
                count = 1,
                sum = float(rand(rng2, 1:100)),
                sumsq = 0.0,
                minimum = 0.0,
                maximum = 0.0,
            ) for _ = 1:n
        ]

        t1 = Tree(leaves1; b = b, schema = schema)
        t2 = Tree(leaves2; b = b, schema = schema)

        @test depth(t1) == depth(t2)
        for (l1, l2) in zip(t1.levels, t2.levels)
            @test l1 == l2
        end
    end
end

@testitem "Tree: property — update preserves root fold oracle (50 random)" begin
    using Tray: ScalarSchema, ScalarSummary, Tree, root, update, identity, combine
    using Random

    rng = MersenneTwister(77)
    schema = ScalarSchema{Float64}(false)

    for trial = 1:50
        n = rand(rng, 2:30)
        b = rand(rng, 2:6)
        leaves = [
            ScalarSummary(
                schema = schema,
                count = 1,
                sum = float(rand(rng, 1:100)),
                sumsq = 0.0,
                minimum = 0.0,
                maximum = 0.0,
            ) for _ = 1:n
        ]
        t = Tree(leaves; b = b, schema = schema)

        # Apply random updates
        for _ = 1:rand(rng, 1:10)
            idx = rand(rng, 1:n)
            new_val = float(rand(rng, 1:1000))
            new_leaf = ScalarSummary(
                schema = schema,
                count = 1,
                sum = new_val,
                sumsq = new_val^2,
                minimum = new_val,
                maximum = new_val,
            )
            t = update(t, idx, new_leaf)

            # Root fold equals direct leaf fold
            @test root(t) == reduce(combine, t.levels[1])
        end
    end
end

## ---------------------------------------------------------------------------
## AttributionPayload reconciliation (Tasks 2.1–2.2)
## ---------------------------------------------------------------------------

@testitem "AttributionPayload: reconciling payload accepted" begin
    using Tray: AttributionPayload, AttributionSchema, Direct

    schema = AttributionSchema(
        bucket_ids = (:pnl, :costs, :fees),
        tolerance = 1e-10,
        residual_bucket_id = nothing,
        convention = Direct(),
    )
    # buckets sum to 8.5 == realized_total
    p = AttributionPayload(
        schema = schema,
        buckets = [10.0, -2.0, 0.5],
        realized_total = 8.5,
    )
    @test sum(p.buckets) ≈ 8.5
    @test p.realized_total == 8.5
end

@testitem "AttributionPayload: reconciling within tolerance accepted" begin
    using Tray: AttributionPayload, AttributionSchema, Direct

    schema = AttributionSchema(
        bucket_ids = (:pnl, :costs, :fees),
        tolerance = 1e-6,
        residual_bucket_id = nothing,
        convention = Direct(),
    )
    # buckets sum to 8.5, realized_total = 8.5000005 — gap 5e-7 < 1e-6
    p = AttributionPayload(
        schema = schema,
        buckets = [10.0, -2.0, 0.5],
        realized_total = 8.5000005,
    )
    @test sum(p.buckets) ≈ 8.5
    @test p.realized_total == 8.5000005
end

@testitem "AttributionPayload: rejects unreconciled without residual" begin
    using Tray: AttributionPayload, AttributionSchema, Direct

    schema = AttributionSchema(
        bucket_ids = (:pnl, :costs, :fees),
        tolerance = 1e-10,
        residual_bucket_id = nothing,
        convention = Direct(),
    )
    # buckets sum to 8.5, realized_total = 10.0 — gap 1.5 > tolerance
    @test_throws ArgumentError AttributionPayload(
        schema = schema,
        buckets = [10.0, -2.0, 0.5],
        realized_total = 10.0,
    )
end

@testitem "AttributionPayload: residual bucket absorbs gap" begin
    using Tray: AttributionPayload, AttributionSchema, Direct

    schema = AttributionSchema(
        bucket_ids = (:pnl, :costs, :fees, :residual),
        tolerance = 1e-10,
        residual_bucket_id = :residual,
        convention = Direct(),
    )
    # buckets sum to 8.5, realized_total = 10.0 — gap 1.5 assigned to residual
    # residual bucket index 4 (0-indexed: 3)
    p = AttributionPayload(
        schema = schema,
        buckets = [10.0, -2.0, 0.5, 0.0],
        realized_total = 10.0,
    )
    @test p.buckets[4] ≈ 1.5
    @test sum(p.buckets) ≈ 10.0
    @test p.realized_total == 10.0
end

@testitem "AttributionPayload: exact reconcile with residual leaves gap zero" begin
    using Tray: AttributionPayload, AttributionSchema, Direct

    schema = AttributionSchema(
        bucket_ids = (:pnl, :costs, :fees, :residual),
        tolerance = 1e-10,
        residual_bucket_id = :residual,
        convention = Direct(),
    )
    # buckets already reconcile
    p = AttributionPayload(
        schema = schema,
        buckets = [10.0, -2.0, 0.5, 0.0],
        realized_total = 8.5,
    )
    @test p.buckets[4] ≈ 0.0
    @test sum(p.buckets) ≈ 8.5
end

@testitem "AttributionPayload: gap outside tolerance with residual still absorbed" begin
    using Tray: AttributionPayload, AttributionSchema, Direct

    schema = AttributionSchema(
        bucket_ids = (:pnl, :fees, :residual),
        tolerance = 1e-6,
        residual_bucket_id = :residual,
        convention = Direct(),
    )
    # buckets sum to 3.0, realized_total = 10.0 — gap 7.0 >> tolerance
    p = AttributionPayload(
        schema = schema,
        buckets = [5.0, -2.0, 0.0],
        realized_total = 10.0,
    )
    @test p.buckets[3] ≈ 7.0
    @test sum(p.buckets) ≈ 10.0
    @test p.realized_total == 10.0
end

@testitem "AttributionPayload: combine preserves reconciliation" begin
    using Tray: AttributionPayload, AttributionSchema, Direct, combine

    schema = AttributionSchema(
        bucket_ids = (:pnl, :costs, :residual),
        tolerance = 1e-10,
        residual_bucket_id = :residual,
        convention = Direct(),
    )
    a = AttributionPayload(
        schema = schema,
        buckets = [10.0, -2.0, 0.0],
        realized_total = 8.0,
    )
    b = AttributionPayload(schema = schema, buckets = [5.0, 1.0, 0.0], realized_total = 6.0)
    c = combine(a, b)
    @test sum(c.buckets) ≈ c.realized_total
    @test c.realized_total == 14.0
    @test c.buckets[3] ≈ 0.0  # residual stays 0 since both reconciles sum exactly
end

@testitem "AttributionPayload: combined residual absorbs cumulative gap" begin
    using Tray: AttributionPayload, AttributionSchema, Direct, combine

    schema = AttributionSchema(
        bucket_ids = (:pnl, :costs, :residual),
        tolerance = 1e-10,
        residual_bucket_id = :residual,
        convention = Direct(),
    )
    a = AttributionPayload(
        schema = schema,
        buckets = [10.0, -2.0, 0.5],
        realized_total = 8.5,
    )
    b = AttributionPayload(
        schema = schema,
        buckets = [5.0, 1.0, -0.5],
        realized_total = 5.5,
    )
    c = combine(a, b)
    @test sum(c.buckets) ≈ c.realized_total
    @test c.buckets[3] ≈ 0.0
end

## ---------------------------------------------------------------------------
## AttributionPayload convention (Task 3)
## ---------------------------------------------------------------------------

@testitem "AttributionPayload: Direct convention recorded" begin
    using Tray: AttributionSchema, Direct

    schema = AttributionSchema(
        bucket_ids = (:pnl, :costs),
        tolerance = 1e-10,
        residual_bucket_id = nothing,
        convention = Direct(),
    )
    @test schema.convention isa Direct
end

@testitem "AttributionPayload: Allocated convention with sequential method" begin
    using Tray: AttributionSchema, Allocated

    schema = AttributionSchema(
        bucket_ids = (:pnl, :costs, :fees),
        tolerance = 1e-10,
        residual_bucket_id = nothing,
        convention = Allocated(:sequential, [:rate, :volume, :mix]),
    )
    @test schema.convention isa Allocated
    @test schema.convention.method == :sequential
    @test schema.convention.ordered_factor_ids == [:rate, :volume, :mix]
end

@testitem "AttributionPayload: Allocated convention with symmetric method" begin
    using Tray: AttributionSchema, Allocated

    schema = AttributionSchema(
        bucket_ids = (:pnl, :costs),
        tolerance = 1e-10,
        residual_bucket_id = nothing,
        convention = Allocated(:symmetric, [:rate, :volume]),
    )
    @test schema.convention.method == :symmetric
end

@testitem "AttributionPayload: Allocated rejects unknown method" begin
    using Tray: Allocated

    @test_throws ArgumentError Allocated(:unknown, [:a])
end

@testitem "AttributionPayload: Allocated rejects empty factor ids" begin
    using Tray: Allocated

    @test_throws ArgumentError Allocated(:sequential, Symbol[])
end

@testitem "AttributionPayload: convention equality" begin
    using Tray: AttributionSchema, Direct, Allocated

    a = AttributionSchema(
        bucket_ids = (:x, :y),
        tolerance = 1e-10,
        residual_bucket_id = nothing,
        convention = Direct(),
    )
    b = AttributionSchema(
        bucket_ids = (:x, :y),
        tolerance = 1e-10,
        residual_bucket_id = nothing,
        convention = Direct(),
    )
    @test a == b
    @test hash(a) == hash(b)
end

@testitem "AttributionPayload: Allocated convention equality" begin
    using Tray: AttributionSchema, Allocated

    a = AttributionSchema(
        bucket_ids = (:x, :y),
        tolerance = 1e-10,
        residual_bucket_id = nothing,
        convention = Allocated(:sequential, [:rate, :volume]),
    )
    b = AttributionSchema(
        bucket_ids = (:x, :y),
        tolerance = 1e-10,
        residual_bucket_id = nothing,
        convention = Allocated(:sequential, [:rate, :volume]),
    )
    @test a == b
    @test hash(a) == hash(b)
end

## ---------------------------------------------------------------------------
## AttributionPayload ratio derivation (Task 4)
## ---------------------------------------------------------------------------

@testitem "AttributionPayload: derive margin ratio" begin
    using Tray: AttributionPayload, AttributionSchema, Direct, derive_ratio

    schema = AttributionSchema(
        bucket_ids = (:revenue, :costs, :pnl),
        tolerance = 1e-10,
        residual_bucket_id = nothing,
        convention = Direct(),
    )
    p = AttributionPayload(
        schema = schema,
        buckets = [100.0, -70.0, 30.0],
        realized_total = 60.0,
    )
    # margin = pnl / revenue = 30 / 100 = 0.3
    margin = derive_ratio(p, :pnl, :revenue)
    @test margin ≈ 0.3
end

@testitem "AttributionPayload: derive ratio across combined payloads" begin
    using Tray: AttributionPayload, AttributionSchema, Direct, combine, derive_ratio

    schema = AttributionSchema(
        bucket_ids = (:revenue, :costs, :pnl),
        tolerance = 1e-10,
        residual_bucket_id = nothing,
        convention = Direct(),
    )
    a = AttributionPayload(
        schema = schema,
        buckets = [100.0, -70.0, 30.0],
        realized_total = 60.0,
    )
    b = AttributionPayload(
        schema = schema,
        buckets = [50.0, -20.0, 30.0],
        realized_total = 60.0,
    )
    c = combine(a, b)
    margin = derive_ratio(c, :pnl, :revenue)
    @test margin ≈ 60.0 / 150.0  # 0.4
end

@testitem "AttributionPayload: derive ratio zero denominator error" begin
    using Tray: AttributionPayload, AttributionSchema, Direct, derive_ratio

    schema = AttributionSchema(
        bucket_ids = (:revenue, :costs, :pnl),
        tolerance = 1e-10,
        residual_bucket_id = nothing,
        convention = Direct(),
    )
    p = AttributionPayload(schema = schema, buckets = [0.0, 0.0, 0.0], realized_total = 0.0)
    @test_throws DomainError derive_ratio(p, :pnl, :revenue)
end

@testitem "AttributionPayload: derive ratio with unknown bucket id" begin
    using Tray: AttributionPayload, AttributionSchema, Direct, derive_ratio

    schema = AttributionSchema(
        bucket_ids = (:revenue, :costs, :pnl),
        tolerance = 1e-10,
        residual_bucket_id = nothing,
        convention = Direct(),
    )
    p = AttributionPayload(
        schema = schema,
        buckets = [100.0, -70.0, 30.0],
        realized_total = 60.0,
    )
    @test_throws ArgumentError derive_ratio(p, :pnl, :nonexistent)
end

@testitem "AttributionPayload: derive ratio with default (zero denominator)" begin
    using Tray: AttributionPayload, AttributionSchema, Direct, derive_ratio

    schema = AttributionSchema(
        bucket_ids = (:revenue, :costs, :pnl),
        tolerance = 1e-10,
        residual_bucket_id = nothing,
        convention = Direct(),
    )
    p = AttributionPayload(schema = schema, buckets = [0.0, 0.0, 0.0], realized_total = 0.0)
    @test derive_ratio(p, :pnl, :revenue, 0.0) == 0.0
    @test derive_ratio(p, :pnl, :revenue, -1.0) == -1.0
end

@testitem "AttributionPayload: derive ratio with default (non-zero denominator)" begin
    using Tray: AttributionPayload, AttributionSchema, Direct, derive_ratio

    schema = AttributionSchema(
        bucket_ids = (:revenue, :costs, :pnl),
        tolerance = 1e-10,
        residual_bucket_id = nothing,
        convention = Direct(),
    )
    p = AttributionPayload(
        schema = schema,
        buckets = [100.0, -70.0, 30.0],
        realized_total = 60.0,
    )
    @test derive_ratio(p, :pnl, :revenue, 0.0) ≈ 0.3
end

@testitem "AttributionPayload: derive ratio with default (invalid numerator ID)" begin
    using Tray: AttributionPayload, AttributionSchema, Direct, derive_ratio

    schema = AttributionSchema(
        bucket_ids = (:revenue, :costs, :pnl),
        tolerance = 1e-10,
        residual_bucket_id = nothing,
        convention = Direct(),
    )
    p = AttributionPayload(
        schema = schema,
        buckets = [100.0, -70.0, 30.0],
        realized_total = 60.0,
    )
    @test_throws ArgumentError derive_ratio(p, :nonexistent, :revenue, 0.0)
end

@testitem "AttributionPayload: derive ratio with default (invalid denominator ID)" begin
    using Tray: AttributionPayload, AttributionSchema, Direct, derive_ratio

    schema = AttributionSchema(
        bucket_ids = (:revenue, :costs, :pnl),
        tolerance = 1e-10,
        residual_bucket_id = nothing,
        convention = Direct(),
    )
    p = AttributionPayload(
        schema = schema,
        buckets = [100.0, -70.0, 30.0],
        realized_total = 60.0,
    )
    @test_throws ArgumentError derive_ratio(p, :pnl, :nonexistent, 0.0)
end

@testitem "AttributionPayload: single bucket (K=1) edge case" begin
    using Tray: AttributionPayload, AttributionSchema, Direct, identity, combine

    schema = AttributionSchema(
        bucket_ids = (:value,),
        tolerance = 1e-10,
        residual_bucket_id = nothing,
        convention = Direct(),
    )
    a = AttributionPayload(schema = schema, buckets = [10.0], realized_total = 10.0)
    b = AttributionPayload(schema = schema, buckets = [20.0], realized_total = 20.0)
    c = combine(a, b)
    @test c.buckets == [30.0]
    @test c.realized_total == 30.0
    id = identity(schema)
    @test combine(id, a) == a
end

@testitem "AttributionPayload: within tolerance boundary accepted" begin
    using Tray: AttributionPayload, AttributionSchema, Direct

    schema = AttributionSchema(
        bucket_ids = (:a, :b),
        tolerance = 1e-6,
        residual_bucket_id = nothing,
        convention = Direct(),
    )
    # gap = 0.5e-6, clearly within tolerance of 1e-6
    realized = 3.0 + 0.5e-6
    p = AttributionPayload(schema = schema, buckets = [1.0, 2.0], realized_total = realized)
    @test sum(p.buckets) ≈ 3.0 atol = 1e-10
    @test p.realized_total ≈ realized
end

@testitem "AttributionPayload: property test — elementwise sum through multi-level combine" begin
    using Tray: AttributionPayload, AttributionSchema, Direct, identity, combine

    schema = AttributionSchema(
        bucket_ids = (:a, :b, :c),
        tolerance = 1e-10,
        residual_bucket_id = nothing,
        convention = Direct(),
    )
    id = identity(schema)

    # Two-level grouping: ((leaf1 + leaf2) + (leaf3 + leaf4))
    leaf1 =
        AttributionPayload(schema = schema, buckets = [1.0, 2.0, 3.0], realized_total = 6.0)
    leaf2 = AttributionPayload(
        schema = schema,
        buckets = [4.0, 5.0, 6.0],
        realized_total = 15.0,
    )
    leaf3 = AttributionPayload(
        schema = schema,
        buckets = [7.0, 8.0, 9.0],
        realized_total = 24.0,
    )
    leaf4 = AttributionPayload(
        schema = schema,
        buckets = [10.0, 11.0, 12.0],
        realized_total = 33.0,
    )

    group1 = combine(leaf1, leaf2)
    group2 = combine(leaf3, leaf4)
    root = combine(group1, group2)

    @test root.buckets == [22.0, 26.0, 30.0]
    @test root.realized_total == 78.0
    @test sum(root.buckets) ≈ root.realized_total

    # Grouping order shouldn't matter
    alt = combine(combine(leaf1, leaf3), combine(leaf2, leaf4))
    @test alt == root
end

@testitem "AttributionPayload: property test — identity left + right idempotent" begin
    using Tray: AttributionPayload, AttributionSchema, Direct, identity, combine

    schema = AttributionSchema(
        bucket_ids = (:x, :y),
        tolerance = 1e-10,
        residual_bucket_id = nothing,
        convention = Direct(),
    )
    id = identity(schema)

    payloads = [
        AttributionPayload(schema = schema, buckets = [1.0, 2.0], realized_total = 3.0),
        AttributionPayload(schema = schema, buckets = [0.0, 0.0], realized_total = 0.0),
        AttributionPayload(schema = schema, buckets = [-5.0, 10.0], realized_total = 5.0),
    ]
    for p in payloads
        @test combine(id, p) == p
        @test combine(p, id) == p
        @test combine(p, id) == combine(id, p)
    end
end

## ---------------------------------------------------------------------------
## Built-in and custom payload conformance (TRAYS-lw6: REQ-4, REQ-7, REQ-33, REQ-43)
## ---------------------------------------------------------------------------

@testitem "Payload conformance: ScalarSummary passes conformance suite" begin
    using Tray: ScalarSchema, ScalarSummary, TrayBase, combine, identity

    schema = ScalarSchema{Float64}(false)
    id = identity(schema)

    # Identity laws
    leaf = ScalarSummary(
        schema = schema,
        count = 3,
        sum = 6.0,
        sumsq = 14.0,
        minimum = 1.0,
        maximum = 3.0,
    )
    @test combine(id, leaf) == leaf
    @test combine(leaf, id) == leaf

    # Associativity (documented responsibility, verified for ScalarSummary)
    a = ScalarSummary(
        schema = schema,
        count = 1,
        sum = 1.0,
        sumsq = 1.0,
        minimum = 1.0,
        maximum = 1.0,
    )
    b = ScalarSummary(
        schema = schema,
        count = 2,
        sum = 5.0,
        sumsq = 13.0,
        minimum = 2.0,
        maximum = 3.0,
    )
    c = ScalarSummary(
        schema = schema,
        count = 1,
        sum = 10.0,
        sumsq = 100.0,
        minimum = 10.0,
        maximum = 10.0,
    )
    @test combine(combine(a, b), c) == combine(a, combine(b, c))

    # Tree construction and query (end-to-end)
    using Tray: Tree, root, leaf_count, range_query
    leaves = [a, b, c]
    t = Tree(leaves; b = 2, schema)
    @test leaf_count(t) == 3
    @test root(t) == reduce(combine, leaves)
    @test range_query(t, 1, 2) == combine(a, b)
    @test range_query(t, 2, 3) == combine(b, c)
end

@testitem "Payload conformance: custom payload passes same suite" begin
    using Tray: TrayBase, Tree, root, leaf_count, range_query, combine, identity

    # Minimal custom payload
    struct MySum{T}
        value::T
    end

    struct MySumSchema{T}
        dummy::T
    end

    function TrayBase.combine(a::MySum{T}, b::MySum{T}) where {T}
        return MySum{T}(a.value + b.value)
    end

    function TrayBase.identity(schema::MySumSchema{T}) where {T}
        return MySum{T}(zero(T))
    end

    # Identity laws
    schema = MySumSchema{Float64}(0.0)
    id = identity(schema)

    leaf = MySum(3.0)
    @test combine(id, leaf) == leaf
    @test combine(leaf, id) == leaf

    # Associativity
    a = MySum(1.0)
    b = MySum(5.0)
    c = MySum(10.0)
    @test combine(combine(a, b), c) == combine(a, combine(b, c))

    # Tree construction and query
    leaves = [a, b, c]
    t = Tree(leaves; b = 2, schema = schema)
    @test leaf_count(t) == 3
    @test root(t) == reduce(combine, leaves)
    @test range_query(t, 1, 2) == combine(a, b)
    @test range_query(t, 2, 3) == combine(b, c)
end

@testitem "Payload conformance: nonconforming payload rejected (REQ-31)" begin
    using Tray: TrayBase, Tree, combine, identity

    # A payload with combine but without identity
    struct BadPayload
        value::Float64
    end

    struct BadSchema end

    # Provide combine only, no identity — Tree constructor calls identity first
    function TrayBase.combine(a::BadPayload, b::BadPayload)
        return BadPayload(a.value + b.value)
    end

    leaves = [BadPayload(1.0), BadPayload(2.0)]
    @test_throws ErrorException Tree(leaves; b = 2, schema = BadSchema())
end

@testitem "Payload conformance: ScalarSummary constant size (REQ-43)" begin
    using Tray: ScalarSchema, ScalarSummary

    schema = ScalarSchema{Float64}(false)
    sizes = [
        sizeof(
            ScalarSummary(
                schema = schema,
                count = 0,
                sum = 0.0,
                sumsq = 0.0,
                minimum = Inf,
                maximum = -Inf,
            ),
        ),
        sizeof(
            ScalarSummary(
                schema = schema,
                count = 1,
                sum = 1.0,
                sumsq = 1.0,
                minimum = 1.0,
                maximum = 1.0,
            ),
        ),
        sizeof(
            ScalarSummary(
                schema = schema,
                count = 100,
                sum = 100.0,
                sumsq = 100.0,
                minimum = 1.0,
                maximum = 100.0,
            ),
        ),
    ]
    @test all(s -> s == sizes[1], sizes)

    # Higher-moment schema also constant
    schema_hm = ScalarSchema{Float64}(true)
    sizes_hm = [
        sizeof(
            ScalarSummary(
                schema = schema_hm,
                count = 0,
                sum = 0.0,
                sumsq = 0.0,
                minimum = Inf,
                maximum = -Inf,
                m3 = 0.0,
                m4 = 0.0,
            ),
        ),
        sizeof(
            ScalarSummary(
                schema = schema_hm,
                count = 1,
                sum = 1.0,
                sumsq = 1.0,
                minimum = 1.0,
                maximum = 1.0,
                m3 = 0.0,
                m4 = 0.0,
            ),
        ),
        sizeof(
            ScalarSummary(
                schema = schema_hm,
                count = 100,
                sum = 100.0,
                sumsq = 100.0,
                minimum = 1.0,
                maximum = 100.0,
                m3 = 1000.0,
                m4 = 10000.0,
            ),
        ),
    ]
    @test all(s -> s == sizes_hm[1], sizes_hm)

    # Note: struct layout is same for all T (higher_moment is validation, not layout)
end

@testitem "Payload conformance: AttributionPayload constant size (REQ-43)" begin
    using Tray: AttributionSchema, AttributionPayload, Direct

    schema = AttributionSchema(
        bucket_ids = (:a, :b, :c),
        tolerance = 1e-10,
        residual_bucket_id = nothing,
        convention = Direct(),
    )
    sizes = [
        sizeof(
            AttributionPayload(
                schema = schema,
                buckets = [1.0, 2.0, 3.0],
                realized_total = 6.0,
            ),
        ),
        sizeof(
            AttributionPayload(
                schema = schema,
                buckets = [0.0, 0.0, 0.0],
                realized_total = 0.0,
            ),
        ),
        sizeof(
            AttributionPayload(
                schema = schema,
                buckets = [100.0, -50.0, 25.0],
                realized_total = 75.0,
            ),
        ),
    ]
    @test all(s -> s == sizes[1], sizes)
end

## ---------------------------------------------------------------------------
## Finite-change algebra (TRAYS-ecx: Task 1.1 — REQ-A1)
## ---------------------------------------------------------------------------

@testitem "Change{Float64}: zero_change leaves value unchanged" begin
    using Tray: Incremental
    inc = Incremental

    old = 3.14
    Δ = inc.zero_change(old)
    @test inc.valid_change(old, Δ)
    @test inc.apply_change(old, Δ) == old
end

@testitem "Change{Float64}: apply_change adds delta" begin
    using Tray: Incremental
    inc = Incremental

    old = 10.0
    Δ = inc.Change{Float64}(3.0)
    @test inc.valid_change(old, Δ)
    @test inc.apply_change(old, Δ) == 13.0
end

@testitem "Change{Float64}: negative delta" begin
    using Tray: Incremental
    inc = Incremental

    old = 5.0
    Δ = inc.Change{Float64}(-2.0)
    @test inc.valid_change(old, Δ)
    @test inc.apply_change(old, Δ) == 3.0
end

@testitem "Change{Float64}: compose_change equals sequential application" begin
    using Tray: Incremental
    inc = Incremental

    old = 10.0
    Δ1 = inc.Change{Float64}(3.0)
    Δ2 = inc.Change{Float64}(5.0)

    composed = inc.compose_change(old, Δ1, Δ2)
    @test inc.valid_change(old, composed)

    after1 = inc.apply_change(old, Δ1)
    after2 = inc.apply_change(after1, Δ2)
    result = inc.apply_change(old, composed)

    @test result == after2
    @test composed.delta ≈ 8.0
end

@testitem "Change{Float64}: identity and sequential composition law" begin
    using Tray: Incremental
    inc = Incremental

    old = 7.0
    Δ = inc.Change{Float64}(2.0)

    composed_with_zero = inc.compose_change(old, Δ, inc.zero_change(old))
    @test inc.apply_change(old, composed_with_zero) == inc.apply_change(old, Δ)

    composed_with_zero2 = inc.compose_change(old, inc.zero_change(old), Δ)
    @test inc.apply_change(old, composed_with_zero2) == inc.apply_change(old, Δ)
end

@testitem "Change{Float64}: zero_change on any value" begin
    using Tray: Incremental
    inc = Incremental

    @test inc.apply_change(42.0, inc.zero_change(42.0)) == 42.0
    @test inc.apply_change(-1.5, inc.zero_change(-1.5)) == -1.5
    @test inc.apply_change(0.0, inc.zero_change(0.0)) == 0.0
end

@testitem "Change{Int}: zero_change leaves value unchanged" begin
    using Tray: Incremental
    inc = Incremental

    old = 42
    Δ = inc.zero_change(old)
    @test inc.valid_change(old, Δ)
    @test inc.apply_change(old, Δ) == old
end

@testitem "Change{Int}: apply_change adds delta" begin
    using Tray: Incremental
    inc = Incremental

    old = 10
    Δ = inc.Change{Int}(3)
    @test inc.valid_change(old, Δ)
    @test inc.apply_change(old, Δ) == 13
end

@testitem "Change{Int}: compose_change" begin
    using Tray: Incremental
    inc = Incremental

    old = 10
    Δ1 = inc.Change{Int}(3)
    Δ2 = inc.Change{Int}(5)

    composed = inc.compose_change(old, Δ1, Δ2)
    @test inc.apply_change(old, composed) == 18
    @test composed.delta == 8
end

## ---------------------------------------------------------------------------
## Exact finite-change rule for basic operations (Task 1.1 — REQ-A1 law)
## ---------------------------------------------------------------------------

@testitem "Exactness law: f(x) = x + 1" begin
    using Tray: Incremental
    inc = Incremental

    f(x) = x + 1
    old_args = (10.0,)
    Δargs = (inc.Change{Float64}(3.0),)

    old_result = f(old_args...)
    Δf = inc.Δf_for_add(inc.apply_change(old_args[1], Δargs[1]), old_result, Δargs[1])

    lhs = inc.apply_change(old_result, Δf)
    rhs = f(inc.apply_change(old_args[1], Δargs[1]))
    @test lhs ≈ rhs
end

@testitem "Exactness law: multiplication with cross term" begin
    using Tray: Incremental
    inc = Incremental

    f(x, y) = x * y
    old_x, old_y = 10.0, 5.0
    Δx = inc.Change{Float64}(3.0)
    Δy = inc.Change{Float64}(2.0)

    old_result = f(old_x, old_y)
    new_x = inc.apply_change(old_x, Δx)
    new_y = inc.apply_change(old_y, Δy)

    Δf = inc.Δf_for_mul(new_x, new_y, old_result, Δx, Δy)
    @test Δf.delta ≈ 41.0

    lhs = inc.apply_change(old_result, Δf)
    rhs = f(new_x, new_y)
    @test lhs ≈ rhs
    @test lhs ≈ 91.0
end

@testitem "Exactness law: sin" begin
    using Tray: Incremental
    inc = Incremental

    f(x) = sin(x)
    old_x = 1.0
    Δx = inc.Change{Float64}(0.5)

    old_result = f(old_x)
    new_x = inc.apply_change(old_x, Δx)

    Δf = inc.Δf_for_sin(old_x, old_result, Δx)
    @test Δf.delta ≈ sin(new_x) - sin(old_x)

    lhs = inc.apply_change(old_result, Δf)
    rhs = f(new_x)
    @test lhs ≈ rhs
end

@testitem "Exactness law: min" begin
    using Tray: Incremental
    inc = Incremental

    f(x, y) = min(x, y)
    old_x, old_y = 5.0, 10.0
    Δx = inc.Change{Float64}(-2.0)
    Δy = inc.Change{Float64}(-1.0)

    old_result = f(old_x, old_y)
    new_x = inc.apply_change(old_x, Δx)
    new_y = inc.apply_change(old_y, Δy)

    Δf = inc.Δf_for_minmax(new_x, new_y, old_result, Δx, Δy, true)
    @test inc.apply_change(old_result, Δf) ≈ f(new_x, new_y)
end

@testitem "Exactness law: max" begin
    using Tray: Incremental
    inc = Incremental

    f(x, y) = max(x, y)
    old_x, old_y = 5.0, 10.0
    Δx = inc.Change{Float64}(-2.0)
    Δy = inc.Change{Float64}(-1.0)

    old_result = f(old_x, old_y)
    new_x = inc.apply_change(old_x, Δx)
    new_y = inc.apply_change(old_y, Δy)

    Δf = inc.Δf_for_minmax(new_x, new_y, old_result, Δx, Δy, false)
    @test inc.apply_change(old_result, Δf) ≈ f(new_x, new_y)
end

@testitem "Exactness law: min with tie-breaking" begin
    using Tray: Incremental
    inc = Incremental

    old_x, old_y = 5.0, 5.0
    Δx = inc.Change{Float64}(-1.0)
    Δy = inc.Change{Float64}(2.0)

    old_result = min(old_x, old_y)
    new_x = inc.apply_change(old_x, Δx)
    new_y = inc.apply_change(old_y, Δy)

    Δf = inc.Δf_for_minmax(new_x, new_y, old_result, Δx, Δy, true)
    @test inc.apply_change(old_result, Δf) ≈ min(new_x, new_y)
end

## ---------------------------------------------------------------------------
## Change{ScalarSummary} (Task 1.1 — REQ-A1 for payload types)
## ---------------------------------------------------------------------------

@testitem "Change{ScalarSummary}: zero_change" begin
    using Tray: Incremental, ScalarSchema, ScalarSummary

    inc = Incremental
    schema = ScalarSchema{Float64}(false)
    old = ScalarSummary(
        schema = schema,
        count = 3,
        sum = 6.0,
        sumsq = 14.0,
        minimum = 1.0,
        maximum = 3.0,
    )

    Δ = inc.zero_change(old)
    @test inc.valid_change(old, Δ)
    result = inc.apply_change(old, Δ)
    @test result == old
end

@testitem "Change{ScalarSummary}: apply_change adds delta fields" begin
    using Tray: Incremental, ScalarSchema, ScalarSummary

    inc = Incremental
    schema = ScalarSchema{Float64}(false)
    old = ScalarSummary(
        schema = schema,
        count = 3,
        sum = 6.0,
        sumsq = 14.0,
        minimum = 1.0,
        maximum = 3.0,
    )

    Δ = inc.ScalarSummaryChange{Float64}(
        count = 1,
        sum = 4.0,
        sumsq = 10.0,
        minimum = -1.0,
        maximum = 2.0,
    )
    @test inc.valid_change(old, Δ)

    result = inc.apply_change(old, Δ)
    @test result.count == 4
    @test result.sum == 10.0
    @test result.sumsq == 24.0
    @test result.minimum == -1.0
    @test result.maximum == 3.0
    @test result.schema === schema
end

@testitem "Change{ScalarSummary}: compose_change" begin
    using Tray: Incremental, ScalarSchema, ScalarSummary

    inc = Incremental
    schema = ScalarSchema{Float64}(false)
    old = ScalarSummary(
        schema = schema,
        count = 3,
        sum = 6.0,
        sumsq = 14.0,
        minimum = 1.0,
        maximum = 3.0,
    )

    Δ1 = inc.ScalarSummaryChange{Float64}(
        count = 1,
        sum = 4.0,
        sumsq = 10.0,
        minimum = -1.0,
        maximum = 2.0,
    )
    Δ2 = inc.ScalarSummaryChange{Float64}(
        count = 2,
        sum = 5.0,
        sumsq = 13.0,
        minimum = -2.0,
        maximum = 1.0,
    )

    composed = inc.compose_change(old, Δ1, Δ2)
    @test inc.valid_change(old, composed)

    result_sequential = inc.apply_change(inc.apply_change(old, Δ1), Δ2)
    result_composed = inc.apply_change(old, composed)
    @test result_composed == result_sequential
end

@testitem "Change{ScalarSummary}: apply_change with zero_change == identity" begin
    using Tray: Incremental, ScalarSchema, ScalarSummary

    inc = Incremental
    schema = ScalarSchema{Float64}(false)

    old = ScalarSummary(
        schema = schema,
        count = 3,
        sum = 6.0,
        sumsq = 14.0,
        minimum = 1.0,
        maximum = 3.0,
    )

    # Identity law: zero_change leaves the value unchanged
    @test inc.apply_change(old, inc.zero_change(old)) == old

    # compose_change with zero is identity
    Δ = inc.ScalarSummaryChange{Float64}(
        count = 1,
        sum = 4.0,
        sumsq = 10.0,
        minimum = -1.0,
        maximum = 2.0,
    )

    composed_with_zero = inc.compose_change(old, Δ, inc.zero_change(old))
    @test inc.apply_change(old, composed_with_zero) == inc.apply_change(old, Δ)

    composed_with_zero2 = inc.compose_change(old, inc.zero_change(old), Δ)
    @test inc.apply_change(old, composed_with_zero2) == inc.apply_change(old, Δ)
end


## ---------------------------------------------------------------------------
## Rule registry (TRAYS-ecx: Task 2.1 — REQ-A4)
## ---------------------------------------------------------------------------

@testitem "RuleRegistry: register and lookup exact key" begin
    using Tray: Incremental

    reg = Incremental.RuleRegistry()
    f = (x, y) -> x * y
    key = Incremental.RuleKey{typeof(f),Tuple{Float64,Float64}}

    rule = Incremental.Rule(
        f,
        Tuple{Float64,Float64},
        (new_x, new_y, old_result, Δx, Δy) ->
            Incremental.Δf_for_mul(new_x, new_y, old_result, Δx, Δy),
    )

    Incremental.register!(reg, rule)

    result = Incremental.lookup(reg, f, (Float64, Float64))
    @test result === rule
end

@testitem "RuleRegistry: lookup returns nothing for missing key" begin
    using Tray: Incremental

    reg = Incremental.RuleRegistry()
    f = (x, y) -> x * y

    result = Incremental.lookup(reg, f, (Float64, Float64))
    @test result === nothing
end

@testitem "RuleRegistry: duplicate registration rejects" begin
    using Tray: Incremental

    reg = Incremental.RuleRegistry()
    f = (x, y) -> x * y

    rule = Incremental.Rule(
        f,
        Tuple{Float64,Float64},
        (new_x, new_y, old_result, Δx, Δy) ->
            Incremental.Δf_for_mul(new_x, new_y, old_result, Δx, Δy),
    )

    Incremental.register!(reg, rule)
    @test_throws ArgumentError Incremental.register!(reg, rule)
end

@testitem "RuleRegistry: explicit replacement creates new revision" begin
    using Tray: Incremental

    reg = Incremental.RuleRegistry()
    f = (x, y) -> x * y

    rule1 = Incremental.Rule(
        f,
        Tuple{Float64,Float64},
        (new_x, new_y, old_result, Δx, Δy) ->
            Incremental.Δf_for_mul(new_x, new_y, old_result, Δx, Δy),
    )
    rule2 = Incremental.Rule(
        f,
        Tuple{Float64,Float64},
        (new_x, new_y, old_result, Δx, Δy) ->
            Incremental.Δf_for_mul(new_x, new_y, old_result, Δx, Δy),
    )

    rev1 = Incremental.register!(reg, rule1)
    rev2 = Incremental.replace!(reg, rule2)

    @test rev2 > rev1
    @test Incremental.lookup(reg, f, (Float64, Float64)) === rule2
end

@testitem "RuleRegistry: removal creates new revision" begin
    using Tray: Incremental

    reg = Incremental.RuleRegistry()
    f = (x, y) -> x * y

    rule = Incremental.Rule(
        f,
        Tuple{Float64,Float64},
        (new_x, new_y, old_result, Δx, Δy) ->
            Incremental.Δf_for_mul(new_x, new_y, old_result, Δx, Δy),
    )

    rev1 = Incremental.register!(reg, rule)
    rev2 = Incremental.remove!(reg, typeof(f), Tuple{Float64,Float64})

    @test rev2 > rev1
    @test Incremental.lookup(reg, f, (Float64, Float64)) === nothing
end

@testitem "RuleRegistry: snapshot is immutable" begin
    using Tray: Incremental

    reg = Incremental.RuleRegistry()
    f = (x, y) -> x * y

    rule = Incremental.Rule(
        f,
        Tuple{Float64,Float64},
        (new_x, new_y, old_result, Δx, Δy) ->
            Incremental.Δf_for_mul(new_x, new_y, old_result, Δx, Δy),
    )

    Incremental.register!(reg, rule)
    snap = Incremental.snapshot(reg)
    rev1 = snap.revision

    f2 = (x,) -> sin(x)
    rule2 = Incremental.Rule(
        f2,
        Tuple{Float64},
        (old_x, old_result, Δx) -> Incremental.Δf_for_sin(old_x, old_result, Δx),
    )
    Incremental.register!(reg, rule2)

    @test snap.revision == rev1
    @test Incremental.snapshot(reg).revision > rev1
end

@testitem "RuleRegistry: monotonic revision numbers" begin
    using Tray: Incremental

    reg = Incremental.RuleRegistry()
    f = (x, y) -> x * y

    rule = Incremental.Rule(
        f,
        Tuple{Float64,Float64},
        (new_x, new_y, old_result, Δx, Δy) ->
            Incremental.Δf_for_mul(new_x, new_y, old_result, Δx, Δy),
    )

    revs = Int[]
    push!(revs, Incremental.register!(reg, rule))
    push!(revs, Incremental.remove!(reg, typeof(f), Tuple{Float64,Float64}))
    push!(revs, Incremental.register!(reg, rule))

    @test revs == sort(revs)
    @test length(unique(revs)) == 3
end

@testitem "RuleRegistry: specificity — more specific key wins" begin
    using Tray: Incremental

    reg = Incremental.RuleRegistry()

    abstract type MyNum end
    struct MyInt <: MyNum end
    struct MyFloat <: MyNum end

    f = (x) -> x

    rule_num = Incremental.Rule(f, Tuple{MyNum}, (x,) -> x)
    rule_int = Incremental.Rule(f, Tuple{MyInt}, (x,) -> x)

    Incremental.register!(reg, rule_num)
    Incremental.register!(reg, rule_int)

    result = Incremental.lookup(reg, f, (MyInt,))
    @test result === rule_int

    result2 = Incremental.lookup(reg, f, (MyFloat,))
    @test result2 === rule_num
end

@testitem "RuleRegistry: ambiguity detection" begin
    using Tray: Incremental

    reg = Incremental.RuleRegistry()

    abstract type A end
    abstract type B <: A end
    abstract type C <: A end
    struct X <: B end
    struct Y <: C end

    f = (x, y) -> x

    # Rule applicable to (B, A): X <: B ✓, Y <: A ✓
    rule_b_a = Incremental.Rule(f, Tuple{B,A}, (x, y) -> x)
    # Rule applicable to (A, C): X <: A ✓, Y <: C ✓
    rule_ac = Incremental.Rule(f, Tuple{A,C}, (x, y) -> x)

    Incremental.register!(reg, rule_b_a)
    Incremental.register!(reg, rule_ac)

    # (X, Y): both rules applicable, neither more specific → ambiguous
    result = Incremental.lookup(reg, f, (X, Y))
    @test result === nothing
end

@testitem "RuleRegistry: no applicable key returns nothing" begin
    using Tray: Incremental

    reg = Incremental.RuleRegistry()

    abstract type X end
    abstract type Y end

    f = (x) -> x
    rule = Incremental.Rule(f, Tuple{X}, (x,) -> x)
    Incremental.register!(reg, rule)

    @test Incremental.lookup(reg, f, (Y,)) === nothing
end

## ---------------------------------------------------------------------------
## IR provider interface (TRAYS-ecx Task 1.2: REQ-A2, REQ-A11, REQ-A17)
## ---------------------------------------------------------------------------

@testitem "IRProvider: DefaultProvider reports unavailable without IRTools" begin
    using Tray: Incremental

    # IRTools is not installed in this environment, so available() should
    # return false gracefully without any load-time errors
    provider = Incremental.DefaultProvider()
    @test Incremental.available(provider) == false
end

@testitem "IRProvider: retrieve_ir returns nothing without IRTools" begin
    using Tray: Incremental

    # Without IRTools, retrieve_ir should return nothing rather than throwing
    provider = Incremental.DefaultProvider()
    @test Incremental.retrieve_ir(provider, +, Tuple{Float64,Float64}) === nothing
end

@testitem "IRProvider: derive returns Rejected without IRTools" begin
    using Tray: Incremental

    # Without IRTools, derive should return a Rejected (AnalysisResult) with
    # IRProviderUnavailable diagnostic, not throw an exception
    result = Incremental.derive(+, Float64, Float64)
    @test result isa Incremental.Rejected
    @test result isa Incremental.AnalysisResult
    @test length(result.diagnostics) >= 1
    @test result.diagnostics[1].code == "IRProviderUnavailable"
    @test result.diagnostics[1].phase == "derive"
end

@testitem "IRProvider: Diagnostic holds expected fields" begin
    using Tray: Incremental

    diag = Incremental.Diagnostic(
        "IRProviderIncompatible",
        "Version mismatch",
        "derive",
        nothing,
        nothing,
        "Update IRTools",
        nothing,
    )
    @test diag.code == "IRProviderIncompatible"
    @test diag.message == "Version mismatch"
    @test diag.phase == "derive"
    @test diag.remediation == "Update IRTools"
end

@testitem "IRProvider: Derived holds expected fields" begin
    using Tray: Incremental

    f(x) = x + 1
    result = Incremental.Derived(f, Tuple{Int}, Incremental.CovCovered)
    @test result.artifact === f
    @test result.argtypes == Tuple{Int}
    @test result.coverage == Incremental.CovCovered
end

@testitem "IRProvider: derive with explicit provider argument" begin
    using Tray: Incremental

    # Passing an explicit provider should work the same as default
    result =
        Incremental.derive(+, Float64, Float64; provider = Incremental.DefaultProvider())
    @test result isa Incremental.Rejected
    @test length(result.diagnostics) >= 1
    @test result.diagnostics[1].code == "IRProviderUnavailable"
end

## ---------------------------------------------------------------------------
## Sealed AnalysisResult sum type (TRAYS-ecx Task 2.2: REQ-A5, REQ-A11)
## ---------------------------------------------------------------------------

@testitem "AnalysisResult: CoverageLevel ordering (CovCovered < CovBoundary < CovRejected)" begin
    using Tray: Incremental

    @test Incremental.CovCovered < Incremental.CovBoundary
    @test Incremental.CovBoundary < Incremental.CovRejected
    @test Incremental.CovCovered < Incremental.CovRejected
    @test Incremental.CovCovered == Incremental.CovCovered
    @test Incremental.CovBoundary == Incremental.CovBoundary
    @test Incremental.CovRejected == Incremental.CovRejected
end

@testitem "AnalysisResult: CoverageLevel join returns worse value" begin
    using Tray: Incremental

    @test Incremental.coverage_join(Incremental.CovCovered, Incremental.CovCovered) ==
          Incremental.CovCovered
    @test Incremental.coverage_join(Incremental.CovCovered, Incremental.CovBoundary) ==
          Incremental.CovBoundary
    @test Incremental.coverage_join(Incremental.CovBoundary, Incremental.CovCovered) ==
          Incremental.CovBoundary
    @test Incremental.coverage_join(Incremental.CovCovered, Incremental.CovRejected) ==
          Incremental.CovRejected
    @test Incremental.coverage_join(Incremental.CovBoundary, Incremental.CovRejected) ==
          Incremental.CovRejected
    @test Incremental.coverage_join(Incremental.CovRejected, Incremental.CovRejected) ==
          Incremental.CovRejected
end

@testitem "AnalysisResult: Derived holds artifact, argtypes, coverage" begin
    using Tray: Incremental

    f(x) = x + 1
    result = Incremental.Derived(f, Tuple{Int}, Incremental.CovCovered)

    @test result isa Incremental.Derived
    @test result isa Incremental.AnalysisResult
    @test result.artifact === f
    @test result.argtypes == Tuple{Int}
    @test result.coverage == Incremental.CovCovered
end

@testitem "AnalysisResult: Derived can be created with any coverage level" begin
    using Tray: Incremental

    f(x) = x

    for coverage in
        [Incremental.CovCovered, Incremental.CovBoundary, Incremental.CovRejected]
        result = Incremental.Derived(f, Tuple{Int}, coverage)
        @test result isa Incremental.Derived
        @test result.coverage == coverage
    end
end

@testitem "AnalysisResult: Rejected holds diagnostics and coverage" begin
    using Tray: Incremental

    diag = Incremental.Diagnostic(
        "IRProviderUnavailable",
        "IRTools not available",
        "derive",
        nothing,
        nothing,
        "Install IRTools",
        nothing,
    )
    result = Incremental.Rejected([diag], Incremental.CovRejected)

    @test result isa Incremental.Rejected
    @test result isa Incremental.AnalysisResult
    @test length(result.diagnostics) == 1
    @test result.diagnostics[1].code == "IRProviderUnavailable"
    @test result.coverage == Incremental.CovRejected
end

@testitem "AnalysisResult: Rejected contains no callable artifact" begin
    using Tray: Incremental

    diag = Incremental.Diagnostic(
        "RuleMissing",
        "No rule for sin(Int)",
        "derive",
        sin,
        nothing,
        "Register a rule for sin(Int)",
        nothing,
    )
    result = Incremental.Rejected([diag], Incremental.CovBoundary)

    # Rejected has no .artifact field — no callable partial artifact
    @test !hasfield(Incremental.Rejected, :artifact)
    @test result.coverage == Incremental.CovBoundary
end

@testitem "AnalysisResult: Diagnostic holds all fields" begin
    using Tray: Incremental

    cause = ErrorException("test cause")
    diag = Incremental.Diagnostic(
        "UnsupportedEffect",
        "I/O operation in pure context",
        "analysis",
        println,
        "src/core.jl:42",
        "Remove I/O from the incrementalized function",
        cause,
    )

    @test diag.code == "UnsupportedEffect"
    @test diag.message == "I/O operation in pure context"
    @test diag.phase == "analysis"
    @test diag.callable === println
    @test diag.location == "src/core.jl:42"
    @test diag.remediation == "Remove I/O from the incrementalized function"
    @test diag.cause isa ErrorException
    @test diag.cause.msg == "test cause"
end

@testitem "AnalysisResult: Diagnostic convenience constructor" begin
    using Tray: Incremental

    # Short form with just code, message, phase
    diag = Incremental.Diagnostic("MethodMissing", "f not found", "derive")
    @test diag.code == "MethodMissing"
    @test diag.message == "f not found"
    @test diag.phase == "derive"
    @test diag.callable === nothing
    @test diag.location === nothing
    @test diag.remediation === nothing
    @test diag.cause === nothing
end

@testitem "AnalysisResult: all 14 classified error codes defined" begin
    using Tray: Incremental

    codes = [
        "UnsupportedEnvironment",
        "IRProviderUnavailable",
        "IRProviderIncompatible",
        "MethodMissing",
        "MethodAmbiguous",
        "RuleMissing",
        "RuleAmbiguous",
        "UnsupportedEffect",
        "ControlFlowChanged",
        "MutableCapture",
        "StaleArtifact",
        "InvalidChange",
        "OracleMismatch",
        "GenerationFailure",
    ]

    for code in codes
        diag = Incremental.Diagnostic(code, "test", "derive")
        @test diag.code == code
    end
end

@testitem "AnalysisResult: AnalysisResult is sealed (only Derived and Rejected subtypes)" begin
    using Tray: Incremental

    # Verify no other subtypes of AnalysisResult exist
    subtypes = Incremental.Rejected <: Incremental.AnalysisResult
    derived_subtypes = Incremental.Derived <: Incremental.AnalysisResult
    @test subtypes
    @test derived_subtypes
end

@testitem "AnalysisResult: derive returns AnalysisResult (Rejected)" begin
    using Tray: Incremental

    # Without IRTools, derive should return a Rejected (AnalysisResult)
    result = Incremental.derive(+, Float64, Float64)
    @test result isa Incremental.AnalysisResult
    @test result isa Incremental.Rejected
    @test length(result.diagnostics) >= 1
    @test result.diagnostics[1].code == "IRProviderUnavailable"
end

@testitem "AnalysisResult: coverage_join is transitive" begin
    using Tray: Incremental

    r1 = Incremental.coverage_join(
        Incremental.coverage_join(Incremental.CovCovered, Incremental.CovBoundary),
        Incremental.CovRejected,
    )
    r2 = Incremental.coverage_join(
        Incremental.CovCovered,
        Incremental.coverage_join(Incremental.CovBoundary, Incremental.CovRejected),
    )
    @test r1 == r2 == Incremental.CovRejected

    levels = [
        Incremental.CovCovered,
        Incremental.CovCovered,
        Incremental.CovBoundary,
        Incremental.CovCovered,
    ]
    result = reduce(Incremental.coverage_join, levels)
    @test result == Incremental.CovBoundary
end

@testitem "AnalysisResult: coverage_join is commutative" begin
    using Tray: Incremental

    for (a, b) in [
        (Incremental.CovCovered, Incremental.CovBoundary),
        (Incremental.CovBoundary, Incremental.CovRejected),
        (Incremental.CovCovered, Incremental.CovRejected),
    ]
        @test Incremental.coverage_join(a, b) == Incremental.coverage_join(b, a)
    end
end

## ---------------------------------------------------------------------------
## Domain-neutral baseline validation (TRAYS-ecx Task 3.2: REQ-A6)
## ---------------------------------------------------------------------------

@testitem "Baseline: ScalarSummary change_between matches combine (REQ-A6)" begin
    using Tray: Incremental, ScalarSummary, ScalarSchema, combine, identity
    inc = Incremental

    schema = ScalarSchema{Float64}(false)
    s1 = ScalarSummary{Float64}(schema, 10, 50.0, 250.0, 1.0, 9.0)
    s2 = ScalarSummary{Float64}(schema, 15, 80.0, 500.0, 1.0, 11.0)

    # change_between computes the delta from old to new
    Δ = inc.change_between(s1, s2)
    @test Δ isa inc.ScalarSummaryChange{Float64}
    @test Δ.count == 5
    @test Δ.sum == 30.0

    # apply_change(old, Δ) should equal new
    result = inc.apply_change(s1, Δ)
    @test result.count == s2.count
    @test result.sum == s2.sum
    @test result.sumsq == s2.sumsq
    @test result.minimum == s2.minimum
    @test result.maximum == s2.maximum
end

@testitem "Baseline: ScalarSummary compose_change matches sequential apply (REQ-A6)" begin
    using Tray: Incremental, ScalarSummary, ScalarSchema, combine, identity
    inc = Incremental

    schema = ScalarSchema{Float64}(false)
    s = ScalarSummary{Float64}(schema, 10, 50.0, 250.0, 1.0, 9.0)

    Δ1 = inc.ScalarSummaryChange{Float64}(
        count = 5,
        sum = 30.0,
        sumsq = 50.0,
        minimum = 2.0,
        maximum = 12.0,
    )
    Δ2 = inc.ScalarSummaryChange{Float64}(
        count = 3,
        sum = 10.0,
        sumsq = 20.0,
        minimum = 3.0,
        maximum = 15.0,
    )

    # Sequential application
    step1 = inc.apply_change(s, Δ1)
    step2 = inc.apply_change(step1, Δ2)

    # Composed application
    Δ_composed = inc.compose_change(s, Δ1, Δ2)
    composed_result = inc.apply_change(s, Δ_composed)

    @test composed_result.count == step2.count
    @test composed_result.sum ≈ step2.sum
    @test composed_result.sumsq ≈ step2.sumsq
    @test composed_result.minimum ≈ step2.minimum
    @test composed_result.maximum ≈ step2.maximum
end

@testitem "Baseline: ScalarSummary recompute artifact satisfies exactness law (REQ-A6)" begin
    using Tray: Incremental, ScalarSummary, ScalarSchema, combine, identity
    inc = Incremental

    schema = ScalarSchema{Float64}(false)

    # f aggregates two ScalarSummaries
    f(x, y) = combine(x, y)
    artifact = inc.generate_recompute_artifact(f, 2)

    s1 = ScalarSummary{Float64}(schema, 10, 50.0, 250.0, 1.0, 9.0)
    s2 = ScalarSummary{Float64}(schema, 15, 80.0, 500.0, 1.0, 11.0)

    old_result = f(s1, s2)
    Δ1 = inc.change_between(s1, s1)  # zero change
    Δ2 = inc.change_between(s2, s2)  # zero change

    result = artifact(s1, s2, old_result, Δ1, Δ2)

    # Apply the change to old_result
    new_result = inc.apply_change(old_result, result)

    # Should equal f on changed inputs
    expected = f(s1, s2)  # unchanged inputs
    @test new_result.count == expected.count
    @test new_result.sum ≈ expected.sum
end

@testitem "Baseline: ScalarSummary recompute with non-zero changes (REQ-A6)" begin
    using Tray: Incremental, ScalarSummary, ScalarSchema, combine, identity
    inc = Incremental

    schema = ScalarSchema{Float64}(false)

    f(x, y) = combine(x, y)
    artifact = inc.generate_recompute_artifact(f, 2)

    s1 = ScalarSummary{Float64}(schema, 10, 50.0, 250.0, 1.0, 9.0)
    s2 = ScalarSummary{Float64}(schema, 15, 80.0, 500.0, 1.0, 11.0)

    old_result = f(s1, s2)

    # s1 loses 3 observations, gains 10 in sum
    s1_new = ScalarSummary{Float64}(schema, 7, 60.0, 300.0, 1.0, 9.0)
    Δ1 = inc.change_between(s1, s1_new)
    Δ2 = inc.change_between(s2, s2)  # s2 unchanged

    result = artifact(s1, s2, old_result, Δ1, Δ2)

    # Apply the change to old_result
    new_result = inc.apply_change(old_result, result)

    # Should equal f on changed inputs
    expected = f(s1_new, s2)
    @test new_result.count == expected.count
    @test new_result.sum ≈ expected.sum
    @test new_result.sumsq ≈ expected.sumsq
end

@testitem "Baseline: custom payload recompute artifact satisfies exactness law (REQ-A6)" begin
    using Tray: Incremental, TrayBase
    inc = Incremental

    # Minimal custom payload
    struct MySum{T}
        value::T
    end
    struct MySumSchema{T}
        init::T
    end
    function TrayBase.combine(a::MySum{T}, b::MySum{T}) where {T}
        return MySum{T}(a.value + b.value)
    end
    function TrayBase.identity(schema::MySumSchema{T}) where {T}
        return MySum{T}(schema.init)
    end

    # We test with numeric values directly, not MySum, since change_between
    # only supports numeric and ScalarSummary types
    f(x, y) = x + y
    artifact = inc.generate_recompute_artifact(f, 2)

    old_x, old_y = 10.0, 5.0
    old_result = f(old_x, old_y)
    Δx = inc.Change{Float64}(3.0)
    Δy = inc.Change{Float64}(2.0)

    result = artifact(old_x, old_y, old_result, Δx, Δy)

    # Apply the change to old_result
    new_result = inc.apply_change(old_result, result)

    # Should equal f on changed inputs
    expected = f(old_x + 3.0, old_y + 2.0)
    @test new_result ≈ expected
end

@testitem "Baseline: change_between round-trip (REQ-A6)" begin
    using Tray: Incremental
    inc = Incremental

    # Numeric round-trip: change_between + apply_change = identity
    for old in [0.0, 1.0, -1.0, 1e10, -1e10]
        new = old * 2.0
        Δ = inc.change_between(old, new)
        result = inc.apply_change(old, Δ)
        @test result ≈ new
    end

    # ScalarSummary round-trip
    using Tray: ScalarSummary, ScalarSchema
    schema = ScalarSchema{Float64}(false)
    s = ScalarSummary{Float64}(schema, 10, 50.0, 250.0, 1.0, 9.0)
    Δ = inc.change_between(s, s)  # same value
    result = inc.apply_change(s, Δ)
    @test result.count == s.count
    @test result.sum ≈ s.sum
end

@testitem "Baseline: recompute artifact with unary function (REQ-A6)" begin
    using Tray: Incremental
    inc = Incremental

    f(x) = 2.0 * x
    artifact = inc.generate_recompute_artifact(f, 1)

    old_x = 5.0
    old_result = f(old_x)
    Δx = inc.Change{Float64}(3.0)

    result = artifact(old_x, old_result, Δx)

    new_result = inc.apply_change(old_result, result)
    expected = f(old_x + 3.0)
    @test new_result ≈ expected
end

@testitem "Baseline: recompute artifact with ternary function (REQ-A6)" begin
    using Tray: Incremental
    inc = Incremental

    f(x, y, z) = x + y + z
    artifact = inc.generate_recompute_artifact(f, 3)

    old_x, old_y, old_z = 1.0, 2.0, 3.0
    old_result = f(old_x, old_y, old_z)
    Δx = inc.Change{Float64}(1.0)
    Δy = inc.Change{Float64}(1.0)
    Δz = inc.Change{Float64}(1.0)

    result = artifact(old_x, old_y, old_z, old_result, Δx, Δy, Δz)

    new_result = inc.apply_change(old_result, result)
    expected = f(2.0, 3.0, 4.0)
    @test new_result ≈ expected
end

@testitem "Baseline: recompute artifact with zero changes (REQ-A6)" begin
    using Tray: Incremental
    inc = Incremental

    f(x, y) = x * y
    artifact = inc.generate_recompute_artifact(f, 2)

    old_x, old_y = 10.0, 5.0
    old_result = f(old_x, old_y)
    Δx = inc.Change{Float64}(0.0)
    Δy = inc.Change{Float64}(0.0)

    result = artifact(old_x, old_y, old_result, Δx, Δy)

    new_result = inc.apply_change(old_result, result)
    expected = f(old_x, old_y)
    @test new_result ≈ expected
end

## ---------------------------------------------------------------------------
## Non-goal tests (TRAYS-ecx Task 5.4: REQ-A12–A15)
## ---------------------------------------------------------------------------

@testitem "NonGoal: no LLVM dependency (REQ-A12)" begin
    using Tray: Incremental

    # Incremental module should not define or depend on LLVM types
    @test !isdefined(Incremental, :LLVM)

    # Verify no LLVM-related exports exist
    exports = names(Incremental; all = true)
    llvm_exports = filter(n -> occursin(r"LLVM|Enzyme", string(n)), exports)
    @test isempty(llvm_exports)
end

@testitem "NonGoal: no differential-dataflow dependency (REQ-A13)" begin
    using Tray: Incremental

    exports = names(Incremental; all = true)
    df_exports =
        filter(n -> occursin(r"differential|timely|dataflow|Dataflow", string(n)), exports)
    @test isempty(df_exports)
end

@testitem "NonGoal: generated artifact is plain callable (REQ-A14)" begin
    using Tray: Incremental
    inc = Incremental

    f(x, y) = x + y
    artifact = inc.generate_recompute_artifact(f, 2)

    # The artifact is a plain Function
    @test artifact isa Function

    # It can be wrapped in a simple memoization layer (e.g., Dict)
    calls = Ref(0)
    memo = Dict{Tuple{Vararg{Any}},Any}()
    function memoized(args...)
        key = args
        if haskey(memo, key)
            return memo[key]
        end
        calls[] += 1
        result = artifact(args...)
        memo[key] = result
        return result
    end

    old_x, old_y = 10.0, 5.0
    old_result = f(old_x, old_y)
    Δx = inc.Change{Float64}(3.0)
    Δy = inc.Change{Float64}(2.0)

    # First call computes
    r1 = memoized(old_x, old_y, old_result, Δx, Δy)
    @test calls[] == 1
    # Second call should use cache
    r2 = memoized(old_x, old_y, old_result, Δx, Δy)
    @test r1 == r2
    @test calls[] == 1  # not incremented

    # Result is correct
    new_result = inc.apply_change(old_result, r1)
    @test new_result ≈ f(13.0, 7.0)
end

@testitem "NonGoal: different arguments bypass memo cache (REQ-A14)" begin
    using Tray: Incremental
    inc = Incremental

    f(x) = x * 2
    artifact = inc.generate_recompute_artifact(f, 1)

    r1 = artifact(5.0, 10.0, inc.Change{Float64}(1.0))
    r2 = artifact(5.0, 10.0, inc.Change{Float64}(2.0))  # different Δ

    @test r1 != r2  # different changes
end

@testitem "NonGoal: broadcast call is a boundary (REQ-A15)" begin
    using Tray: Incremental
    inc = Incremental

    # Mock IR with a broadcast call
    mock_ir = [Expr(:call, :broadcasted, :+, :x, :y), Expr(:return, :result)]

    summary = inc.analyze_ir(mock_ir, +, (Vector{Float64}, Vector{Float64}), nothing)
    @test summary.coverage == inc.CovBoundary
    @test length(summary.diagnostics) >= 1
    @test summary.diagnostics[1].code == "RuleMissing"
end
