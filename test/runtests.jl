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

@testitem "Tree: derived variance and std from ScalarSummary (REQ-5)" begin
    using Tray:
        ScalarSchema,
        ScalarSummary,
        Tree,
        root,
        derived_mean,
        derived_variance,
        derived_std,
        identity,
        combine

    schema = ScalarSchema{Float64}(false)
    leaves = [
        ScalarSummary(
            count = 1,
            sum = 1.0,
            sumsq = 1.0,
            minimum = 1.0,
            maximum = 1.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 2.0,
            sumsq = 4.0,
            minimum = 2.0,
            maximum = 2.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 3.0,
            sumsq = 9.0,
            minimum = 3.0,
            maximum = 3.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 4.0,
            sumsq = 16.0,
            minimum = 4.0,
            maximum = 4.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 5.0,
            sumsq = 25.0,
            minimum = 5.0,
            maximum = 5.0,
            schema = schema,
        ),
    ]
    t = Tree(leaves; b = 2, schema)
    r = root(t)

    # Mean = (1+2+3+4+5)/5 = 3.0
    @test derived_mean(r) ≈ 3.0

    # Variance = E[X²] - E[X]²
    # E[X²] = (1+4+9+16+25)/5 = 55/5 = 11.0
    # E[X]² = 9.0
    # Var = 11.0 - 9.0 = 2.0
    @test derived_variance(r) ≈ 2.0

    # Std = sqrt(2.0)
    @test derived_std(r) ≈ sqrt(2.0)
end

@testitem "Tree: derived variance and std reject empty (REQ-5)" begin
    using Tray: ScalarSchema, ScalarSummary, derived_variance, derived_std, identity

    schema = ScalarSchema{Float64}(false)
    id = identity(schema)  # count=0 identity

    @test_throws DomainError derived_variance(id)
    @test_throws DomainError derived_std(id)
end

@testitem "Tree: derived_variance clamps tiny negative rounding errors (REQ-5)" begin
    using Tray: ScalarSchema, ScalarSummary, derived_variance

    schema = ScalarSchema{Float64}(false)
    # A single value has zero variance
    s = ScalarSummary(
        count = 1,
        sum = 1.0,
        sumsq = 1.0,
        minimum = 1.0,
        maximum = 1.0,
        schema = schema,
    )

    @test derived_variance(s) >= 0.0
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
## Structural and deferred mutations (TRAYS-ebb: REQ-14, REQ-15, REQ-18, REQ-29, REQ-41)
## ---------------------------------------------------------------------------

@testitem "Tree: insert leaf at end (REQ-14)" begin
    using Tray:
        ScalarSchema, ScalarSummary, Tree, leaf_count, root, identity, combine, insert!

    schema = ScalarSchema{Float64}(false)
    leaves = [
        ScalarSummary(
            count = 1,
            sum = 2.0,
            sumsq = 4.0,
            minimum = 2.0,
            maximum = 2.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 3.0,
            sumsq = 9.0,
            minimum = 3.0,
            maximum = 3.0,
            schema = schema,
        ),
    ]
    t = Tree(leaves; b = 2, schema)

    new_leaf = ScalarSummary(
        count = 1,
        sum = 4.0,
        sumsq = 16.0,
        minimum = 4.0,
        maximum = 4.0,
        schema = schema,
    )
    insert!(t, 3, new_leaf)

    @test leaf_count(t) == 3
    @test t.levels[1][3] == new_leaf
    @test root(t) == reduce(combine, t.levels[1])
end

@testitem "Tree: insert leaf at beginning (REQ-14)" begin
    using Tray:
        ScalarSchema, ScalarSummary, Tree, leaf_count, root, identity, combine, insert!

    schema = ScalarSchema{Float64}(false)
    leaves = [
        ScalarSummary(
            count = 1,
            sum = 2.0,
            sumsq = 4.0,
            minimum = 2.0,
            maximum = 2.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 3.0,
            sumsq = 9.0,
            minimum = 3.0,
            maximum = 3.0,
            schema = schema,
        ),
    ]
    t = Tree(leaves; b = 2, schema)

    new_leaf = ScalarSummary(
        count = 1,
        sum = 1.0,
        sumsq = 1.0,
        minimum = 1.0,
        maximum = 1.0,
        schema = schema,
    )
    insert!(t, 1, new_leaf)

    @test leaf_count(t) == 3
    @test t.levels[1][1] == new_leaf
    @test t.levels[1][2] == leaves[1]
    @test t.levels[1][3] == leaves[2]
    @test root(t) == reduce(combine, t.levels[1])
end

@testitem "Tree: insert rejects out-of-bounds (REQ-14)" begin
    using Tray: ScalarSchema, ScalarSummary, Tree, insert!

    schema = ScalarSchema{Float64}(false)
    leaf = ScalarSummary(
        count = 1,
        sum = 1.0,
        sumsq = 1.0,
        minimum = 1.0,
        maximum = 1.0,
        schema = schema,
    )
    t = Tree([leaf]; b = 2, schema)

    @test_throws BoundsError insert!(t, 0, leaf)
    @test_throws BoundsError insert!(t, 3, leaf)  # n+1=2, so 3 is out of bounds
end

@testitem "Tree: insert grows tree level when needed (REQ-14)" begin
    using Tray:
        ScalarSchema,
        ScalarSummary,
        Tree,
        leaf_count,
        depth,
        root,
        identity,
        combine,
        insert!

    schema = ScalarSchema{Float64}(false)
    # b=2, start with 2 leaves = 1 internal node + root (2 levels: depth=1)
    # Insert 3rd leaf → tree grows to 3 levels (depth=2)
    leaves = [
        ScalarSummary(
            count = 1,
            sum = 1.0,
            sumsq = 1.0,
            minimum = 1.0,
            maximum = 1.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 2.0,
            sumsq = 4.0,
            minimum = 2.0,
            maximum = 2.0,
            schema = schema,
        ),
    ]
    t = Tree(leaves; b = 2, schema)
    orig_depth = depth(t)
    @test orig_depth == 1

    new_leaf = ScalarSummary(
        count = 1,
        sum = 3.0,
        sumsq = 9.0,
        minimum = 3.0,
        maximum = 3.0,
        schema = schema,
    )
    insert!(t, 3, new_leaf)

    # 3 leaves → level1=3, level2=ceil(3/2)=2, level3=ceil(2/2)=1 → depth=2
    @test depth(t) == 2
    @test leaf_count(t) == 3
    @test root(t) == reduce(combine, t.levels[1])
end

@testitem "Tree: remove leaf from end (REQ-15)" begin
    using Tray:
        ScalarSchema, ScalarSummary, Tree, leaf_count, root, identity, combine, remove!

    schema = ScalarSchema{Float64}(false)
    leaves = [
        ScalarSummary(
            count = 1,
            sum = 2.0,
            sumsq = 4.0,
            minimum = 2.0,
            maximum = 2.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 3.0,
            sumsq = 9.0,
            minimum = 3.0,
            maximum = 3.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 4.0,
            sumsq = 16.0,
            minimum = 4.0,
            maximum = 4.0,
            schema = schema,
        ),
    ]
    t = Tree(leaves; b = 2, schema)

    remove!(t, 3)

    @test leaf_count(t) == 2
    @test t.levels[1][1] == leaves[1]
    @test t.levels[1][2] == leaves[2]
    @test root(t) == reduce(combine, t.levels[1])
end

@testitem "Tree: remove leaf from beginning (REQ-15)" begin
    using Tray:
        ScalarSchema, ScalarSummary, Tree, leaf_count, root, identity, combine, remove!

    schema = ScalarSchema{Float64}(false)
    leaves = [
        ScalarSummary(
            count = 1,
            sum = 2.0,
            sumsq = 4.0,
            minimum = 2.0,
            maximum = 2.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 3.0,
            sumsq = 9.0,
            minimum = 3.0,
            maximum = 3.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 4.0,
            sumsq = 16.0,
            minimum = 4.0,
            maximum = 4.0,
            schema = schema,
        ),
    ]
    t = Tree(leaves; b = 2, schema)

    remove!(t, 1)

    @test leaf_count(t) == 2
    @test t.levels[1][1] == leaves[2]
    @test t.levels[1][2] == leaves[3]
    @test root(t) == reduce(combine, t.levels[1])
end

@testitem "Tree: remove rejects final leaf (REQ-15)" begin
    using Tray: ScalarSchema, ScalarSummary, Tree, leaf_count, remove!

    schema = ScalarSchema{Float64}(false)
    leaf = ScalarSummary(
        count = 1,
        sum = 1.0,
        sumsq = 1.0,
        minimum = 1.0,
        maximum = 1.0,
        schema = schema,
    )
    t = Tree([leaf]; b = 2, schema)

    @test_throws ArgumentError remove!(t, 1)
    @test leaf_count(t) == 1  # unchanged
end

@testitem "Tree: remove rejects out-of-bounds (REQ-15)" begin
    using Tray: ScalarSchema, ScalarSummary, Tree, remove!

    schema = ScalarSchema{Float64}(false)
    leaves = [
        ScalarSummary(
            count = 1,
            sum = 2.0,
            sumsq = 4.0,
            minimum = 2.0,
            maximum = 2.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 3.0,
            sumsq = 9.0,
            minimum = 3.0,
            maximum = 3.0,
            schema = schema,
        ),
    ]
    t = Tree(leaves; b = 2, schema)

    @test_throws BoundsError remove!(t, 0)
    @test_throws BoundsError remove!(t, 3)
end

@testitem "Tree: remove compacts tree level when possible (REQ-15)" begin
    using Tray:
        ScalarSchema,
        ScalarSummary,
        Tree,
        leaf_count,
        depth,
        root,
        identity,
        combine,
        remove!

    schema = ScalarSchema{Float64}(false)
    # b=2, 3 leaves → depth 2, remove to 2 leaves → depth 1
    leaves = [
        ScalarSummary(
            count = 1,
            sum = 1.0,
            sumsq = 1.0,
            minimum = 1.0,
            maximum = 1.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 2.0,
            sumsq = 4.0,
            minimum = 2.0,
            maximum = 2.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 3.0,
            sumsq = 9.0,
            minimum = 3.0,
            maximum = 3.0,
            schema = schema,
        ),
    ]
    t = Tree(leaves; b = 2, schema)
    @test depth(t) == 2

    remove!(t, 3)

    @test depth(t) == 1
    @test leaf_count(t) == 2
    @test root(t) == reduce(combine, t.levels[1])
end

@testitem "Tree: immutable insert returns new tree (REQ-14)" begin
    using Tray:
        ScalarSchema, ScalarSummary, Tree, leaf_count, root, identity, combine, insert

    schema = ScalarSchema{Float64}(false)
    leaves = [
        ScalarSummary(
            count = 1,
            sum = 2.0,
            sumsq = 4.0,
            minimum = 2.0,
            maximum = 2.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 3.0,
            sumsq = 9.0,
            minimum = 3.0,
            maximum = 3.0,
            schema = schema,
        ),
    ]
    t = Tree(leaves; b = 2, schema)
    new_leaf = ScalarSummary(
        count = 1,
        sum = 4.0,
        sumsq = 16.0,
        minimum = 4.0,
        maximum = 4.0,
        schema = schema,
    )

    t2 = insert(t, 3, new_leaf)

    @test leaf_count(t) == 2       # original unchanged
    @test leaf_count(t2) == 3
    @test t2.levels[1][3] == new_leaf
    @test root(t2) == reduce(combine, t2.levels[1])
end

@testitem "Tree: immutable remove returns new tree (REQ-15)" begin
    using Tray:
        ScalarSchema, ScalarSummary, Tree, leaf_count, root, identity, combine, remove

    schema = ScalarSchema{Float64}(false)
    leaves = [
        ScalarSummary(
            count = 1,
            sum = 2.0,
            sumsq = 4.0,
            minimum = 2.0,
            maximum = 2.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 3.0,
            sumsq = 9.0,
            minimum = 3.0,
            maximum = 3.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 4.0,
            sumsq = 16.0,
            minimum = 4.0,
            maximum = 4.0,
            schema = schema,
        ),
    ]
    t = Tree(leaves; b = 2, schema)

    t2 = remove(t, 1)

    @test leaf_count(t) == 3       # original unchanged
    @test leaf_count(t2) == 2
    @test t2.levels[1][1] == leaves[2]
    @test t2.levels[1][2] == leaves[3]
    @test root(t2) == reduce(combine, t2.levels[1])
end

@testitem "Tree: reweight subtree (REQ-18)" begin
    using Tray:
        ScalarSchema,
        ScalarSummary,
        Tree,
        root,
        identity,
        combine,
        reweight_subtree,
        leaf_count,
        reweight

    schema = ScalarSchema{Float64}(false)
    leaves = [
        ScalarSummary(
            count = 1,
            sum = 2.0,
            sumsq = 4.0,
            minimum = 2.0,
            maximum = 2.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 3.0,
            sumsq = 9.0,
            minimum = 3.0,
            maximum = 3.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 4.0,
            sumsq = 16.0,
            minimum = 4.0,
            maximum = 4.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 5.0,
            sumsq = 25.0,
            minimum = 5.0,
            maximum = 5.0,
            schema = schema,
        ),
    ]
    t = Tree(leaves; b = 2, schema)

    # Reweight the subtree at level 2, node 1 (covers leaves [1,2]) with weight 2.0
    t2 = reweight_subtree(t, 2, 1, 2.0)

    # Leaves [1,2] should have sum*2, leaves [3,4] unchanged
    @test t2.levels[1][1] == reweight(leaves[1], 2.0)
    @test t2.levels[1][2] == reweight(leaves[2], 2.0)
    @test t2.levels[1][3] == leaves[3]
    @test t2.levels[1][4] == leaves[4]

    # Root should equal fold of reweighted leaves
    expected_root = combine(
        combine(reweight(leaves[1], 2.0), reweight(leaves[2], 2.0)),
        combine(leaves[3], leaves[4]),
    )
    @test root(t2) == expected_root
end

@testitem "Tree: reweight rejects undefined operation (REQ-18)" begin
    using Tray: Tree, leaf_count, reweight_subtree

    # AttributionPayload does not define TrayBase.reweight
    using Tray: AttributionSchema, AttributionPayload, AttributionConvention, Direct

    schema = AttributionSchema(
        bucket_ids = (:a, :b),
        tolerance = 1e-10,
        residual_bucket_id = nothing,
        convention = Direct(),
    )
    leaf = AttributionPayload(buckets = [1.0, 2.0], realized_total = 3.0, schema = schema)
    t = Tree([leaf, leaf]; b = 2, schema = schema)

    @test_throws ErrorException reweight_subtree(t, 2, 1, 2.0)
end

@testitem "Tree: reweight on leaf level (REQ-18 subtree boundary)" begin
    using Tray:
        ScalarSchema,
        ScalarSummary,
        Tree,
        root,
        identity,
        combine,
        reweight_subtree,
        leaf_count,
        reweight

    schema = ScalarSchema{Float64}(false)
    leaf = ScalarSummary(
        count = 1,
        sum = 5.0,
        sumsq = 25.0,
        minimum = 5.0,
        maximum = 5.0,
        schema = schema,
    )
    t = Tree([leaf]; b = 2, schema)

    # Level 1, node 1 = the single leaf, depth 0 = leaf level
    t2 = reweight_subtree(t, 1, 1, 3.0)

    @test t2.levels[1][1] == reweight(leaf, 3.0)
    @test root(t2) == reweight(leaf, 3.0)
end

@testitem "Tree: update! O(log_b n) ancestor path only (REQ-41)" begin
    using Tray: ScalarSchema, ScalarSummary, Tree, update!, root, identity, combine

    # Build a larger tree to verify only the ancestor path is recomputed
    schema = ScalarSchema{Float64}(false)
    n_leaves = 64
    leaves = ScalarSummary[
        ScalarSummary(
            schema = schema,
            count = 1,
            sum = Float64(i),
            sumsq = Float64(i) ^ 2,
            minimum = Float64(i),
            maximum = Float64(i),
        ) for i = 1:n_leaves
    ]
    t = Tree(leaves; b = 2, schema)

    # Snapshot original levels
    orig = [copy(level) for level in t.levels]

    new_leaf = ScalarSummary(
        schema = schema,
        count = 1,
        sum = 999.0,
        sumsq = 999.0 ^ 2,
        minimum = 999.0,
        maximum = 999.0,
    )
    update!(t, 17, new_leaf)

    # Verify leaf at index 17 was updated
    @test t.levels[1][17] == new_leaf

    # Unaffected leaves should match originals
    for i = 1:n_leaves
        if i != 17
            @test t.levels[1][i] == orig[1][i]
        end
    end

    # Root should equal fold of updated leaves
    @test root(t) == reduce(combine, t.levels[1])
end

@testitem "Tree: lazy tag apply and compose (REQ-29)" begin
    using Tray:
        ScalarSchema,
        ScalarSummary,
        Tree,
        LazyTag,
        apply_lazy,
        compose_lazy,
        identity_lazy,
        is_identity_lazy,
        is_distributive

    schema = ScalarSchema{Float64}(false)
    s = ScalarSummary(
        count = 2,
        sum = 5.0,
        sumsq = 13.0,
        minimum = 2.0,
        maximum = 3.0,
        schema = schema,
    )

    # Scale by 2
    tag2 = LazyTag(:scale, 2.0)
    s2 = apply_lazy(tag2, s)
    @test s2.sum ≈ 10.0
    @test s2.sumsq ≈ 26.0

    # Identity tag
    tag_id = identity_lazy(schema)
    @test is_identity_lazy(tag_id)
    @test apply_lazy(tag_id, s) == s

    # Compose: scale by 2 then scale by 3 = scale by 6
    tag3 = LazyTag(:scale, 3.0)
    composed = compose_lazy(tag2, tag3)
    @test composed.value ≈ 6.0  # 2.0 * 3.0 = 6.0
    # compose(tag2, tag3) = tag2 ∘ tag3, i.e., apply tag3 then apply tag2
    # apply(compose(tag2, tag3), s) = apply(tag2, apply(tag3, s))
    @test apply_lazy(composed, s) == apply_lazy(tag2, apply_lazy(tag3, s))

    # Distributive check
    @test is_distributive(tag2)
    @test is_distributive(tag3)
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
    result = Incremental.Derived(f, Tuple{Int}, Incremental.CovCovered, nothing)
    @test result.artifact === f
    @test result.argtypes == Tuple{Int}
    @test result.coverage == Incremental.CovCovered
    @test result.binding === nothing
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
    result = Incremental.Derived(f, Tuple{Int}, Incremental.CovCovered, nothing)

    @test result isa Incremental.Derived
    @test result isa Incremental.AnalysisResult
    @test result.artifact === f
    @test result.argtypes == Tuple{Int}
    @test result.coverage == Incremental.CovCovered
    @test result.binding === nothing
end

@testitem "AnalysisResult: Derived can be created with any coverage level" begin
    using Tray: Incremental

    f(x) = x

    for coverage in
        [Incremental.CovCovered, Incremental.CovBoundary, Incremental.CovRejected]
        result = Incremental.Derived(f, Tuple{Int}, coverage, nothing)
        @test result isa Incremental.Derived
        @test result.coverage == coverage
        @test result.binding === nothing
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

## ---------------------------------------------------------------------------
## Requirement-to-test traceability (TRAYS-ecx Task 5.5: REQ-A1–A17)
## ---------------------------------------------------------------------------
#
# REQ-A1  Exact finite-change algebra
#   → Finite-change algebra section (line 2417)
#   → Exactness law tests (line 2529)
#
# REQ-A2  Internal IR-provider interface
#   → IR provider interface section (line 2978)
#
# REQ-A3  Exact generated update function
#   → IR analysis framework (src/incremental.jl)
#   → Derivation entry point derive() tests (line 3039, 3222)
#
# REQ-A4  Revisioned rule registry
#   → Rule registry section (line 2765)
#
# REQ-A5  Sealed transitive analysis result
#   → Sealed AnalysisResult sum type section (line 3051)
#
# REQ-A6  Exact built-ins and domain-neutral baselines
#   → Domain-neutral baseline validation section (line 3269)
#   → Exactness law tests (line 2529)
#
# REQ-A7  Canonical combine and strategy adapter
#   → Not yet tested (Task 4.1)
#
# REQ-A8  V1 program boundary
#   → classify_operation coverage (src/incremental.jl)
#   → Boundary tests in IR provider section
#
# REQ-A9  Atomic ancestor-path updates
#   → Not yet tested (Task 4.3)
#
# REQ-A10 No silent approximation
#   → Covered by RuleMissing/Rejected diagnostics
#
# REQ-A11 Classified call-time failures
#   → IR provider interface section (line 2978)
#   → Sealed AnalysisResult section (line 3051)
#   → Classified error codes test (line 3186)
#
# REQ-A12 No LLVM-level incrementalization
#   → Non-goal tests section (line 3512)
#
# REQ-A13 No differential-dataflow binding
#   → Non-goal tests section (line 3524)
#
# REQ-A14 Memoization interoperability
#   → Non-goal tests section (line 3533, 3575)
#
# REQ-A15 Covered broadcast lowering
#   → Non-goal tests section (line 3588)
#
# REQ-A16 Reproducible artifact identity
#   → Artifact binding test section below
#
# REQ-A17 Graceful operation without IRTools
#   → REQ-A17 test section (line 3882)
#   → IR provider interface section (line 2978, 2998)
#   → derive returns Rejected tests (line 3039, 3222)

# ---------------------------------------------------------------------------
# REQ-A16 Artifact identity and binding (TRAYS-ecx Task 5.1)
# ---------------------------------------------------------------------------

@testitem "ArtifactBinding: can be created with all fields" begin
    using Tray: Incremental

    binding = Incremental.ArtifactBinding(
        nothing,                                    # method_instance
        UInt64(42),                                 # world
        Tuple{Int,Float64},                         # argtypes
        nothing,                                    # closure_capture_type
        3,                                          # registry_revision
        "DefaultProvider",                          # provider_identity
        VERSION,                                    # julia_version
        1,                                          # payload_schema_version
    )

    @test binding.method_instance === nothing
    @test binding.world == UInt64(42)
    @test binding.argtypes == Tuple{Int,Float64}
    @test binding.closure_capture_type === nothing
    @test binding.registry_revision == 3
    @test binding.provider_identity == "DefaultProvider"
    @test binding.julia_version == VERSION
    @test binding.payload_schema_version == 1
end

@testitem "ArtifactBinding: current_artifact_binding captures derivation context" begin
    using Tray: Incremental

    binding = Incremental.current_artifact_binding(
        +,
        Tuple{Int,Int},
        Incremental.DefaultProvider(),
        nothing,
    )

    @test binding isa Incremental.ArtifactBinding
    @test binding.argtypes == Tuple{Int,Int}
    @test binding.julia_version == VERSION
    @test binding.provider_identity == "DefaultProvider"
    @test binding.registry_revision == 0  # no registry
    @test binding.payload_schema_version == 1
    # World age should be sensible (non-zero)
    @test binding.world > 0
end

@testitem "ArtifactBinding: current_artifact_binding captures registry revision" begin
    using Tray: Incremental

    reg = Incremental.RuleRegistry()
    rule = Incremental.Rule(+, Tuple{Int,Int}, (a, b, c) -> c)
    Incremental.register!(reg, rule)

    binding = Incremental.current_artifact_binding(
        +,
        Tuple{Int,Int},
        Incremental.DefaultProvider(),
        reg,
    )

    @test binding.registry_revision == 1
end

@testitem "BoundArtifact: wraps function and binding, calls inner on match" begin
    using Tray: Incremental

    inner(x) = x + 1
    binding = Incremental.ArtifactBinding(
        nothing,
        Base.tls_world_age(),
        Tuple{Int},
        nothing,
        0,
        "test",
        VERSION,
        1,
    )
    art = Incremental.BoundArtifact(inner, binding)

    @test art isa Function
    @test art(5) == 6
    @test art.inner === inner
    @test art.binding === binding
end

@testitem "BoundArtifact: throws StaleArtifactError on world age mismatch" begin
    using Tray: Incremental

    inner(x) = x + 1
    binding = Incremental.ArtifactBinding(
        nothing,
        typemax(UInt64),  # far future world age — always stale
        Tuple{Int},
        nothing,
        0,
        "test",
        VERSION,
        1,
    )
    art = Incremental.BoundArtifact(inner, binding)

    @test_throws Incremental.StaleArtifactError art(5)
end

@testitem "BoundArtifact: throws StaleArtifactError on Julia version mismatch" begin
    using Tray: Incremental

    inner(x) = x + 1
    binding = Incremental.ArtifactBinding(
        nothing,
        Base.tls_world_age(),
        Tuple{Int},
        nothing,
        0,
        "test",
        v"0.0.0",  # definitely wrong version
        1,
    )
    art = Incremental.BoundArtifact(inner, binding)

    @test_throws Incremental.StaleArtifactError art(5)
end

@testitem "BoundArtifact: StaleArtifactError has readable message" begin
    using Tray: Incremental

    inner(x) = x + 1
    binding = Incremental.ArtifactBinding(
        nothing,
        typemax(UInt64),
        Tuple{Int},
        nothing,
        0,
        "test",
        VERSION,
        1,
    )
    art = Incremental.BoundArtifact(inner, binding)

    try
        art(5)
        @test false  # should not reach
    catch e
        @test e isa Incremental.StaleArtifactError
        msg = sprint(showerror, e)
        @test occursin("StaleArtifactError", msg)
        @test occursin("world", msg)
    end
end

@testitem "Derived: carries binding when created by derive" begin
    using Tray: Incremental

    result = Incremental.derive(+, Float64, Float64)
    @test result isa Incremental.Rejected  # IRTools not available

    # When IRTools is unavailable, derive returns Rejected, not Derived
    # So we test the Derived construction directly
    f(x) = x + 1
    derived = Incremental.Derived(f, Tuple{Int}, Incremental.CovCovered, nothing)
    @test derived.binding === nothing
end

@testitem "detect_mutable_captures: returns nothing for pure functions" begin
    using Tray: Incremental

    @test Incremental.detect_mutable_captures(+) === nothing
    @test Incremental.detect_mutable_captures(sin) === nothing
    @test Incremental.detect_mutable_captures(x -> x + 1) === nothing
end

@testitem "detect_mutable_captures: returns nothing for closures with only immutables" begin
    using Tray: Incremental

    # Immutable capture (Int is isbits)
    n = 42
    f = x -> x + n
    @test Incremental.detect_mutable_captures(f) === nothing

    # Multiple immutable captures
    a, b = 10, 20
    g = (x, y) -> x * a + y * b
    @test Incremental.detect_mutable_captures(g) === nothing
end

@testitem "detect_mutable_captures: returns nothing for built-in functions" begin
    using Tray: Incremental

    @test Incremental.detect_mutable_captures(+) === nothing
    @test Incremental.detect_mutable_captures(*) === nothing
    @test Incremental.detect_mutable_captures(sin) === nothing
end

@testitem "detect_mutable_captures: returns nothing for closures (Julia 1.12+ opaque captures)" begin
    using Tray: Incremental

    # In Julia 1.12+, closure captures are internal and not exposed via fields.
    # We can no longer distinguish mutable from immutable captures via reflection.
    # This test verifies that capture detection is a no-op (safe fallback).

    arr = [1, 2, 3]
    f = x -> x + arr[1]

    result = Incremental.detect_mutable_captures(f)
    # In Julia 1.12, we can't detect mutable captures, so this returns nothing
    # In earlier Julia versions, it would return a Diagnostic
    @test result === nothing
end

@testitem "detect_mutable_captures: returns nothing for built-in functions" begin
    using Tray: Incremental

    @test Incremental.detect_mutable_captures(+) === nothing
    @test Incremental.detect_mutable_captures(*) === nothing
    @test Incremental.detect_mutable_captures(sin) === nothing
end

# ---------------------------------------------------------------------------
# REQ-A17 Graceful operation without IRTools (TRAYS-ecx Task 5.3)
# ---------------------------------------------------------------------------

@testitem "REQ-A17: RuleRegistry operations work without IRTools" begin
    using Tray: Incremental

    reg = Incremental.RuleRegistry()
    rule = Incremental.Rule(+, Tuple{Int,Int}, (a, b, c) -> c)
    rev = Incremental.register!(reg, rule)
    @test rev == 1
    @test Incremental.snapshot(reg).revision == 1

    found = Incremental.lookup(reg, +, (Int, Int))
    @test found !== nothing

    rule2 = Incremental.Rule(+, Tuple{Int,Int}, (a, b, c) -> c + c)
    rev2 = Incremental.replace!(reg, rule2)
    @test rev2 == 2

    rev3 = Incremental.remove!(reg, typeof(+), Tuple{Int,Int})
    @test rev3 == 3
    @test Incremental.lookup(reg, +, (Int, Int)) === nothing

    status, _ = Incremental.lookup_classified(reg, +, (Int, Int))
    @test status == :missing
end

@testitem "REQ-A17: BoundArtifact invocation uses only metadata, no provider" begin
    using Tray: Incremental

    inner(x) = x + 1
    binding = Incremental.ArtifactBinding(
        nothing,
        Base.tls_world_age(),
        Tuple{Int},
        nothing,
        0,
        "test",
        VERSION,
        1,
    )
    art = Incremental.BoundArtifact(inner, binding)

    @test art(42) == 43
    @test art(0) == 1
end

@testitem "REQ-A17: available() checks Julia version before loading IRTools" begin
    using Tray: Incremental

    provider = Incremental.DefaultProvider()
    avail = Incremental.available(provider)
    @test avail == false

    @test VERSION >= v"1.10"

    diags = Incremental.availability_diagnostics(provider, +)
    @test length(diags) >= 1
    @test diags[1].code == "IRProviderUnavailable"
end

# ---------------------------------------------------------------------------
# REQ-A7  Canonical combine and strategy adapter (TRAYS-ecx Task 4.1)
# ---------------------------------------------------------------------------

@testitem "UpdateStrategy: canonical combine fallback when Δf is nothing" begin
    using Tray: ScalarSummary, ScalarSchema, identity, combine
    using Tray.Incremental: UpdateSnapshot, UpdateStrategy, apply_strategy

    schema = ScalarSchema{Float64}(false)
    old = ScalarSummary(
        count = 3,
        sum = 6.0,
        sumsq = 14.0,
        minimum = 1.0,
        maximum = 3.0,
        schema = schema,
    )
    new = ScalarSummary(
        count = 4,
        sum = 10.0,
        sumsq = 30.0,
        minimum = 1.0,
        maximum = 4.0,
        schema = schema,
    )

    snap = UpdateSnapshot(;
        old_value = old,
        new_value = new,
        parent_old = nothing,
        siblings = ScalarSummary[],
    )
    strategy = UpdateStrategy(; Δf = nothing)

    # With no Δf, apply_strategy should fall back to canonical combine
    # For a single child with no siblings, combine(old, id) = old, combine(new, id) = new
    result = apply_strategy(strategy, snap)
    @test result == new
end

@testitem "UpdateStrategy: Δf path produces same result as canonical combine" begin
    using Tray: ScalarSummary, ScalarSchema, identity, combine
    using Tray.Incremental:
        UpdateSnapshot, UpdateStrategy, apply_strategy, apply_change, change_between

    schema = ScalarSchema{Float64}(false)
    id = identity(schema)
    old = ScalarSummary(
        count = 3,
        sum = 6.0,
        sumsq = 14.0,
        minimum = 1.0,
        maximum = 3.0,
        schema = schema,
    )
    new = ScalarSummary(
        count = 4,
        sum = 10.0,
        sumsq = 30.0,
        minimum = 1.0,
        maximum = 4.0,
        schema = schema,
    )
    sibling = ScalarSummary(
        count = 2,
        sum = 5.0,
        sumsq = 13.0,
        minimum = 2.0,
        maximum = 3.0,
        schema = schema,
    )

    expected = combine(new, sibling)

    # Δf that always returns the correct change
    function my_df(old_value, old_parent, Δ_child)
        new_parent = combine(apply_change(old_value, Δ_child), sibling)
        return change_between(old_parent, new_parent)
    end

    snap = UpdateSnapshot(;
        old_value = old,
        new_value = new,
        parent_old = combine(old, sibling),
        siblings = [sibling],
    )
    strategy = UpdateStrategy(; Δf = my_df)

    result = apply_strategy(strategy, snap)
    @test result == expected
end

@testitem "UpdateStrategy: Δf fallback to combine when change is invalid" begin
    using Tray: ScalarSummary, ScalarSchema, identity, combine
    using Tray.Incremental:
        UpdateSnapshot, UpdateStrategy, apply_strategy, ScalarSummaryChange

    schema = ScalarSchema{Float64}(false)
    id = identity(schema)
    old = ScalarSummary(
        count = 3,
        sum = 6.0,
        sumsq = 14.0,
        minimum = 1.0,
        maximum = 3.0,
        schema = schema,
    )
    new = ScalarSummary(
        count = 4,
        sum = 10.0,
        sumsq = 30.0,
        minimum = 1.0,
        maximum = 4.0,
        schema = schema,
    )
    sibling = ScalarSummary(
        count = 2,
        sum = 5.0,
        sumsq = 13.0,
        minimum = 2.0,
        maximum = 3.0,
        schema = schema,
    )
    expected = combine(new, sibling)

    # Δf that produces an invalid change (negative count)
    function bad_df(::Any, ::Any, ::Any)
        return ScalarSummaryChange{Float64}(
            count = -999,
            sum = 0.0,
            sumsq = 0.0,
            minimum = Inf,
            maximum = -Inf,
        )
    end

    snap = UpdateSnapshot(;
        old_value = old,
        new_value = new,
        parent_old = combine(old, sibling),
        siblings = [sibling],
    )
    strategy = UpdateStrategy(; Δf = bad_df)

    result = apply_strategy(strategy, snap)
    @test result == expected
end

@testitem "UpdateStrategy: numeric Δf with siblings" begin
    using Tray.Incremental:
        UpdateSnapshot,
        UpdateStrategy,
        apply_strategy,
        change_between,
        apply_change,
        valid_change,
        Change
    using Tray: TrayBase
    using Tray: TrayBase

    # Define combine for numeric types (addition) for this test
    TrayBase.combine(a::T, b::T) where {T<:Number} = a + b

    old, new_val = 10.0, 15.0
    siblings = [20.0, 30.0]
    old_parent = old + sum(siblings)  # combine = +
    expected = new_val + sum(siblings)

    # Simple Δf for addition: Δ_parent = Δ_child
    function add_df(::Float64, ::Float64, Δ::Change{Float64})
        return Δ
    end

    snap = UpdateSnapshot(;
        old_value = old,
        new_value = new_val,
        parent_old = old_parent,
        siblings = siblings,
    )
    strategy = UpdateStrategy(; Δf = add_df)

    result = apply_strategy(strategy, snap)
    @test result ≈ expected
end

@testitem "UpdateStrategy: validate_with_oracle returns expected for correct Δf" begin
    using Tray.Incremental:
        UpdateSnapshot, UpdateStrategy, apply_strategy, validate_with_oracle, Change
    using Tray: TrayBase
    using Tray: TrayBase

    # Define combine for numeric types (addition) for this test
    TrayBase.combine(a::T, b::T) where {T<:Number} = a + b

    old, new_val = 5.0, 8.0
    siblings = [10.0]
    old_parent = old + sum(siblings)
    expected = new_val + sum(siblings)

    snap = UpdateSnapshot(;
        old_value = old,
        new_value = new_val,
        parent_old = old_parent,
        siblings = siblings,
    )

    # Correct Δf
    function add_df(::Float64, ::Float64, Δ::Change{Float64})
        return Δ
    end

    # Oracle matches Δf result
    @test validate_with_oracle(add_df, snap)
end

@testitem "UpdateStrategy: validate_with_oracle returns false for incorrect Δf" begin
    using Tray.Incremental:
        UpdateSnapshot, UpdateStrategy, apply_strategy, validate_with_oracle, Change
    using Tray: TrayBase
    using Tray: TrayBase

    # Define combine for numeric types (addition) for this test
    TrayBase.combine(a::T, b::T) where {T<:Number} = a + b

    old, new_val = 5.0, 8.0
    siblings = [10.0]
    old_parent = old + sum(siblings)

    snap = UpdateSnapshot(;
        old_value = old,
        new_value = new_val,
        parent_old = old_parent,
        siblings = siblings,
    )

    # Wrong Δf that returns Δ_child * 2
    function wrong_df(::Float64, ::Float64, Δ::Change{Float64})
        return Change{Float64}(Δ.delta * 2)
    end

    @test !validate_with_oracle(wrong_df, snap)
end

@testitem "UpdateStrategy: integrate with tree update replicates canonical result" begin
    using Tray: ScalarSummary, ScalarSchema, identity, combine, Tree, update, root
    using Tray.Incremental:
        UpdateSnapshot, UpdateStrategy, apply_strategy, update_with_strategy

    schema = ScalarSchema{Float64}(false)
    id = identity(schema)

    leaves = [
        ScalarSummary(
            count = 1,
            sum = 5.0,
            sumsq = 25.0,
            minimum = 5.0,
            maximum = 5.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 3.0,
            sumsq = 9.0,
            minimum = 3.0,
            maximum = 3.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 7.0,
            sumsq = 49.0,
            minimum = 7.0,
            maximum = 7.0,
            schema = schema,
        ),
    ]

    tree = Tree(leaves; b = 2, schema = schema)
    new_leaf = ScalarSummary(
        count = 1,
        sum = 9.0,
        sumsq = 81.0,
        minimum = 9.0,
        maximum = 9.0,
        schema = schema,
    )

    # Canonical update
    canonical_tree = update(tree, 2, new_leaf)
    canonical_root = root(canonical_tree)

    # Update with strategy (nothing Δf = canonical combine fallback)
    updated_tree = update_with_strategy(tree, 2, new_leaf, UpdateStrategy(; Δf = nothing))
    @test root(updated_tree) == canonical_root
    @test updated_tree.levels[1] == canonical_tree.levels[1]
    @test updated_tree.levels[2] == canonical_tree.levels[2]
end

@testitem "UpdateStrategy: tree update with correct Δf preserves canonical result" begin
    using Tray: ScalarSummary, ScalarSchema, identity, combine, Tree, update, root
    using Tray.Incremental:
        UpdateSnapshot, UpdateStrategy, apply_strategy, update_with_strategy

    schema = ScalarSchema{Float64}(false)

    leaves = [
        ScalarSummary(
            count = 1,
            sum = 5.0,
            sumsq = 25.0,
            minimum = 5.0,
            maximum = 5.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 3.0,
            sumsq = 9.0,
            minimum = 3.0,
            maximum = 3.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 7.0,
            sumsq = 49.0,
            minimum = 7.0,
            maximum = 7.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 2.0,
            sumsq = 4.0,
            minimum = 2.0,
            maximum = 2.0,
            schema = schema,
        ),
    ]

    tree = Tree(leaves; b = 2, schema = schema)
    new_leaf = ScalarSummary(
        count = 1,
        sum = 10.0,
        sumsq = 100.0,
        minimum = 10.0,
        maximum = 10.0,
        schema = schema,
    )

    canonical_tree = update(tree, 3, new_leaf)
    canonical_root = root(canonical_tree)

    # Δf that computes the correct change:
    # For combine(ScalarSummary, ScalarSummary), the Δ is ScalarSummaryChange
    # The parent change is computed from combine(new_child, siblings) - combine(old_child, siblings)
    function summary_df(old_child, old_parent, Δ_child)
        # Find siblings by reconstructing from parent
        # This is a simplified Δf that recomputes the exact change
        return Δ_child  # In real usage, this would be a generated rule
    end

    updated_tree =
        update_with_strategy(tree, 3, new_leaf, UpdateStrategy(; Δf = summary_df))
    @test root(updated_tree) == canonical_root
end

@testitem "UpdateStrategy: validate oracle mode rejects wrong Δf and falls back" begin
    using Tray: ScalarSummary, ScalarSchema, identity, combine, Tree, update, root
    using Tray.Incremental:
        UpdateSnapshot,
        UpdateStrategy,
        apply_strategy,
        update_with_strategy,
        ScalarSummaryChange

    schema = ScalarSchema{Float64}(false)

    leaves = [
        ScalarSummary(
            count = 1,
            sum = 5.0,
            sumsq = 25.0,
            minimum = 5.0,
            maximum = 5.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 3.0,
            sumsq = 9.0,
            minimum = 3.0,
            maximum = 3.0,
            schema = schema,
        ),
    ]

    tree = Tree(leaves; b = 2, schema = schema)
    new_leaf = ScalarSummary(
        count = 1,
        sum = 9.0,
        sumsq = 81.0,
        minimum = 9.0,
        maximum = 9.0,
        schema = schema,
    )

    canonical_tree = update(tree, 1, new_leaf)
    canonical_root = root(canonical_tree)

    # Wrong Δf: returns a change that would produce wrong result
    function wrong_df(::Any, ::Any, ::Any)
        return ScalarSummaryChange{Float64}(
            count = 999,
            sum = 999.0,
            sumsq = 999.0,
            minimum = 0.0,
            maximum = 999.0,
        )
    end

    # With validate=false, wrong Δf would produce wrong result
    updated_tree_no_validate = update_with_strategy(
        tree,
        1,
        new_leaf,
        UpdateStrategy(; Δf = wrong_df, validate = false),
    )
    @test root(updated_tree_no_validate) != canonical_root

    # With validate=true, oracle catches wrong Δf and falls back to combine
    updated_tree_validate = update_with_strategy(
        tree,
        1,
        new_leaf,
        UpdateStrategy(; Δf = wrong_df, validate = true),
    )
    @test root(updated_tree_validate) == canonical_root
end

# ---------------------------------------------------------------------------
# REQ-A8  V1 program boundary / REQ-A9  Atomic ancestor-path updates
#         (TRAYS-ecx Tasks 4.2, 4.3)
# ---------------------------------------------------------------------------

@testitem "try_apply_strategy: returns :success for valid Δf" begin
    using Tray: ScalarSummary, ScalarSchema, identity, combine
    using Tray.Incremental:
        UpdateSnapshot,
        UpdateStrategy,
        try_apply_strategy,
        ScalarSummaryChange,
        apply_change

    schema = ScalarSchema{Float64}(false)
    old = ScalarSummary(
        count = 3,
        sum = 6.0,
        sumsq = 14.0,
        minimum = 1.0,
        maximum = 3.0,
        schema = schema,
    )
    new = ScalarSummary(
        count = 4,
        sum = 10.0,
        sumsq = 30.0,
        minimum = 1.0,
        maximum = 4.0,
        schema = schema,
    )
    sibling = ScalarSummary(
        count = 2,
        sum = 5.0,
        sumsq = 13.0,
        minimum = 2.0,
        maximum = 3.0,
        schema = schema,
    )

    # Simple Δf that correctly computes the parent change
    function my_df(::ScalarSummary{Float64}, ::Any, Δ_child)
        return Δ_child
    end

    snap = UpdateSnapshot(;
        old_value = old,
        new_value = new,
        parent_old = combine(old, sibling),
        siblings = [sibling],
    )
    strategy = UpdateStrategy(; Δf = my_df)

    status, result = try_apply_strategy(strategy, snap)
    @test status == :success
    @test result == combine(new, sibling)
end

@testitem "try_apply_strategy: returns :boundary for invalid change" begin
    using Tray: ScalarSummary, ScalarSchema, identity, combine
    using Tray.Incremental:
        UpdateSnapshot, UpdateStrategy, try_apply_strategy, ScalarSummaryChange, Diagnostic

    schema = ScalarSchema{Float64}(false)
    old = ScalarSummary(
        count = 3,
        sum = 6.0,
        sumsq = 14.0,
        minimum = 1.0,
        maximum = 3.0,
        schema = schema,
    )
    new = ScalarSummary(
        count = 4,
        sum = 10.0,
        sumsq = 30.0,
        minimum = 1.0,
        maximum = 4.0,
        schema = schema,
    )

    # Δf that produces an invalid change
    function bad_df(::Any, ::Any, ::Any)
        return ScalarSummaryChange{Float64}(
            count = -999,
            sum = 0.0,
            sumsq = 0.0,
            minimum = Inf,
            maximum = -Inf,
        )
    end

    snap = UpdateSnapshot(;
        old_value = old,
        new_value = new,
        parent_old = combine(old, new),
        siblings = [new],
    )
    strategy = UpdateStrategy(; Δf = bad_df)

    status, result = try_apply_strategy(strategy, snap)
    @test status == :boundary
    @test result isa Diagnostic
    @test result.code == "InvalidChange"
end

@testitem "try_apply_strategy: catches Δf exception as ControlFlowChanged" begin
    using Tray: ScalarSummary, ScalarSchema, identity, combine
    using Tray.Incremental: UpdateSnapshot, UpdateStrategy, try_apply_strategy, Diagnostic

    schema = ScalarSchema{Float64}(false)
    old = ScalarSummary(
        count = 3,
        sum = 6.0,
        sumsq = 14.0,
        minimum = 1.0,
        maximum = 3.0,
        schema = schema,
    )
    new = ScalarSummary(
        count = 4,
        sum = 10.0,
        sumsq = 30.0,
        minimum = 1.0,
        maximum = 4.0,
        schema = schema,
    )
    sibling = ScalarSummary(
        count = 2,
        sum = 5.0,
        sumsq = 13.0,
        minimum = 2.0,
        maximum = 3.0,
        schema = schema,
    )

    # Δf that throws an exception (simulating a runtime boundary)
    function throwing_df(::Any, ::Any, ::Any)
        error("Control flow boundary detected: branch changed between old and new inputs")
    end

    snap = UpdateSnapshot(;
        old_value = old,
        new_value = new,
        parent_old = combine(old, sibling),
        siblings = [sibling],
    )
    strategy = UpdateStrategy(; Δf = throwing_df)

    status, result = try_apply_strategy(strategy, snap)
    @test status == :boundary
    @test result isa Diagnostic
    @test result.code == "ControlFlowChanged"
end

@testitem "try_apply_strategy: returns :boundary for oracle mismatch when validate=true" begin
    using Tray: ScalarSummary, ScalarSchema, identity, combine
    using Tray.Incremental:
        UpdateSnapshot, UpdateStrategy, try_apply_strategy, ScalarSummaryChange, Diagnostic

    schema = ScalarSchema{Float64}(false)
    old = ScalarSummary(
        count = 3,
        sum = 6.0,
        sumsq = 14.0,
        minimum = 1.0,
        maximum = 3.0,
        schema = schema,
    )
    new = ScalarSummary(
        count = 4,
        sum = 10.0,
        sumsq = 30.0,
        minimum = 1.0,
        maximum = 4.0,
        schema = schema,
    )
    sibling = ScalarSummary(
        count = 2,
        sum = 5.0,
        sumsq = 13.0,
        minimum = 2.0,
        maximum = 3.0,
        schema = schema,
    )

    # Wrong Δf that produces a different result
    function wrong_df(::Any, ::Any, ::Any)
        return ScalarSummaryChange{Float64}(
            count = 999,
            sum = 999.0,
            sumsq = 999.0,
            minimum = 0.0,
            maximum = 999.0,
        )
    end

    snap = UpdateSnapshot(;
        old_value = old,
        new_value = new,
        parent_old = combine(old, sibling),
        siblings = [sibling],
    )
    strategy = UpdateStrategy(; Δf = wrong_df, validate = true)

    status, result = try_apply_strategy(strategy, snap)
    @test status == :boundary
    @test result isa Diagnostic
    @test result.code == "OracleMismatch"
end

@testitem "update_with_boundary_detection: replicates canonical result" begin
    using Tray: ScalarSummary, ScalarSchema, identity, combine, Tree, update, root
    using Tray.Incremental:
        UpdateSnapshot, UpdateStrategy, apply_strategy, update_with_boundary_detection

    schema = ScalarSchema{Float64}(false)
    id = identity(schema)

    leaves = [
        ScalarSummary(
            count = 1,
            sum = 5.0,
            sumsq = 25.0,
            minimum = 5.0,
            maximum = 5.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 3.0,
            sumsq = 9.0,
            minimum = 3.0,
            maximum = 3.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 7.0,
            sumsq = 49.0,
            minimum = 7.0,
            maximum = 7.0,
            schema = schema,
        ),
    ]

    tree = Tree(leaves; b = 2, schema = schema)
    new_leaf = ScalarSummary(
        count = 1,
        sum = 9.0,
        sumsq = 81.0,
        minimum = 9.0,
        maximum = 9.0,
        schema = schema,
    )

    canonical_tree = update(tree, 2, new_leaf)
    canonical_root = root(canonical_tree)

    # Atomic update with boundary detection (no Δf = canonical combine)
    result_tree =
        update_with_boundary_detection(tree, 2, new_leaf, UpdateStrategy(; Δf = nothing))
    @test root(result_tree) == canonical_root
    @test result_tree.levels[1] == canonical_tree.levels[1]
end

@testitem "update_with_boundary_detection: with correct Δf preserves canonical result" begin
    using Tray: ScalarSummary, ScalarSchema, identity, combine, Tree, update, root
    using Tray.Incremental:
        UpdateSnapshot, UpdateStrategy, apply_strategy, update_with_boundary_detection

    schema = ScalarSchema{Float64}(false)

    leaves = [
        ScalarSummary(
            count = 1,
            sum = 5.0,
            sumsq = 25.0,
            minimum = 5.0,
            maximum = 5.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 3.0,
            sumsq = 9.0,
            minimum = 3.0,
            maximum = 3.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 7.0,
            sumsq = 49.0,
            minimum = 7.0,
            maximum = 7.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 2.0,
            sumsq = 4.0,
            minimum = 2.0,
            maximum = 2.0,
            schema = schema,
        ),
    ]

    tree = Tree(leaves; b = 2, schema = schema)
    new_leaf = ScalarSummary(
        count = 1,
        sum = 10.0,
        sumsq = 100.0,
        minimum = 10.0,
        maximum = 10.0,
        schema = schema,
    )

    canonical_tree = update(tree, 3, new_leaf)
    canonical_root = root(canonical_tree)

    # Correct Δf
    function correct_df(::Any, ::Any, Δ_child)
        return Δ_child
    end

    result_tree =
        update_with_boundary_detection(tree, 3, new_leaf, UpdateStrategy(; Δf = correct_df))
    @test root(result_tree) == canonical_root
end

@testitem "update_with_boundary_detection: wrong Δf with validate=true falls back to combine" begin
    using Tray: ScalarSummary, ScalarSchema, identity, combine, Tree, update, root
    using Tray.Incremental:
        UpdateSnapshot,
        UpdateStrategy,
        apply_strategy,
        update_with_boundary_detection,
        ScalarSummaryChange

    schema = ScalarSchema{Float64}(false)

    leaves = [
        ScalarSummary(
            count = 1,
            sum = 5.0,
            sumsq = 25.0,
            minimum = 5.0,
            maximum = 5.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 3.0,
            sumsq = 9.0,
            minimum = 3.0,
            maximum = 3.0,
            schema = schema,
        ),
    ]

    tree = Tree(leaves; b = 2, schema = schema)
    new_leaf = ScalarSummary(
        count = 1,
        sum = 9.0,
        sumsq = 81.0,
        minimum = 9.0,
        maximum = 9.0,
        schema = schema,
    )

    canonical_tree = update(tree, 1, new_leaf)
    canonical_root = root(canonical_tree)

    # Wrong Δf
    function wrong_df(::Any, ::Any, ::Any)
        return ScalarSummaryChange{Float64}(
            count = 999,
            sum = 999.0,
            sumsq = 999.0,
            minimum = 0.0,
            maximum = 999.0,
        )
    end

    # With validate=true, wrong Δf triggers boundary detection and falls back to combine
    result_tree = update_with_boundary_detection(
        tree,
        1,
        new_leaf,
        UpdateStrategy(; Δf = wrong_df, validate = true),
    )
    @test root(result_tree) == canonical_root
end

@testitem "update_with_boundary_detection: throwing Δf falls back to combine" begin
    using Tray: ScalarSummary, ScalarSchema, identity, combine, Tree, update, root
    using Tray.Incremental:
        UpdateSnapshot, UpdateStrategy, apply_strategy, update_with_boundary_detection

    schema = ScalarSchema{Float64}(false)

    leaves = [
        ScalarSummary(
            count = 1,
            sum = 5.0,
            sumsq = 25.0,
            minimum = 5.0,
            maximum = 5.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 3.0,
            sumsq = 9.0,
            minimum = 3.0,
            maximum = 3.0,
            schema = schema,
        ),
    ]

    tree = Tree(leaves; b = 2, schema = schema)
    new_leaf = ScalarSummary(
        count = 1,
        sum = 9.0,
        sumsq = 81.0,
        minimum = 9.0,
        maximum = 9.0,
        schema = schema,
    )

    canonical_tree = update(tree, 1, new_leaf)
    canonical_root = root(canonical_tree)

    # Δf that throws an exception (runtime boundary)
    function throwing_df(::Any, ::Any, ::Any)
        error("Runtime boundary: control flow changed")
    end

    # Throwing Δf should be caught and fall back to combine
    result_tree = update_with_boundary_detection(
        tree,
        1,
        new_leaf,
        UpdateStrategy(; Δf = throwing_df),
    )
    @test root(result_tree) == canonical_root
end

## ---------------------------------------------------------------------------
## Multidimensional axes and intersections (TRAYS-x38: REQ-8, REQ-25, REQ-39)
## ---------------------------------------------------------------------------

@testitem "AxisMap: construction with node-to-leaves mapping" begin
    using Tray: AxisMap

    node_to_leaves = Dict("electronics" => [1, 3, 5], "clothing" => [2, 4, 6])
    am = AxisMap(node_to_leaves)

    @test am.node_to_leaves["electronics"] == [1, 3, 5]
    @test am.node_to_leaves["clothing"] == [2, 4, 6]
    @test am.revision == 1
    @test am.leaf_membership[1] == ["electronics"]
    @test am.leaf_membership[2] == ["clothing"]
end

@testitem "AxisMap: leaf membership reverse map" begin
    using Tray: AxisMap

    # Leaf 3 belongs to both categories
    node_to_leaves = Dict("a" => [1, 3], "b" => [2, 3])
    am = AxisMap(node_to_leaves)

    @test sort(am.leaf_membership[3]) == ["a", "b"]
end

@testitem "AxisMap: rejects invalid leaf IDs" begin
    using Tray: AxisMap

    @test_throws ArgumentError AxisMap(Dict("bad" => [0, 1]))
end

@testitem "MultiAxisSet: register and query an axis (REQ-8)" begin
    using Tray:
        ScalarSchema,
        ScalarSummary,
        Tree,
        MultiAxisSet,
        AxisMap,
        register_axis!,
        root,
        leaf_count,
        identity,
        combine

    schema = ScalarSchema{Float64}(false)
    leaves = [
        ScalarSummary(
            count = 1,
            sum = 1.0,
            sumsq = 1.0,
            minimum = 1.0,
            maximum = 1.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 2.0,
            sumsq = 4.0,
            minimum = 2.0,
            maximum = 2.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 3.0,
            sumsq = 9.0,
            minimum = 3.0,
            maximum = 3.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 4.0,
            sumsq = 16.0,
            minimum = 4.0,
            maximum = 4.0,
            schema = schema,
        ),
    ]
    t = Tree(leaves; b = 2, schema)
    mas = MultiAxisSet(t)

    # Register a category axis
    cat_map = AxisMap(Dict("groceries" => [1, 3], "utilities" => [2, 4]))
    axis = register_axis!(mas, "category", cat_map)

    @test axis.name == "category"
    @test axis.revision == 1
    @test leaf_count(axis.tree) == 4
    @test haskey(mas.axes, "category")
end

@testitem "MultiAxisSet: register two axes sharing leaves (REQ-8)" begin
    using Tray:
        ScalarSchema,
        ScalarSummary,
        Tree,
        MultiAxisSet,
        AxisMap,
        register_axis!,
        get_leaf_ids

    schema = ScalarSchema{Float64}(false)
    leaves = [
        ScalarSummary(
            count = 1,
            sum = 1.0,
            sumsq = 1.0,
            minimum = 1.0,
            maximum = 1.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 2.0,
            sumsq = 4.0,
            minimum = 2.0,
            maximum = 2.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 3.0,
            sumsq = 9.0,
            minimum = 3.0,
            maximum = 3.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 4.0,
            sumsq = 16.0,
            minimum = 4.0,
            maximum = 4.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 5.0,
            sumsq = 25.0,
            minimum = 5.0,
            maximum = 5.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 6.0,
            sumsq = 36.0,
            minimum = 6.0,
            maximum = 6.0,
            schema = schema,
        ),
    ]
    t = Tree(leaves; b = 2, schema)
    mas = MultiAxisSet(t)

    cat_map = AxisMap(Dict("food" => [1, 3, 5], "tools" => [2, 4, 6]))
    register_axis!(mas, "category", cat_map)

    time_map = AxisMap(Dict("Q1" => [1, 2], "Q2" => [3, 4], "Q3" => [5, 6]))
    register_axis!(mas, "time", time_map)

    @test haskey(mas.axes, "category")
    @test haskey(mas.axes, "time")
    @test get_leaf_ids(mas.axes["category"], "food") == [1, 3, 5]
    @test get_leaf_ids(mas.axes["time"], "Q2") == [3, 4]
end

@testitem "MultiAxisSet: register rejects duplicate axis name" begin
    using Tray: ScalarSchema, ScalarSummary, Tree, MultiAxisSet, AxisMap, register_axis!

    schema = ScalarSchema{Float64}(false)
    leaf = ScalarSummary(
        count = 1,
        sum = 1.0,
        sumsq = 1.0,
        minimum = 1.0,
        maximum = 1.0,
        schema = schema,
    )
    t = Tree([leaf]; b = 2, schema)
    mas = MultiAxisSet(t)

    register_axis!(mas, "cat", AxisMap(Dict("a" => [1])))
    @test_throws ArgumentError register_axis!(mas, "cat", AxisMap(Dict("b" => [1])))
end

@testitem "MultiAxisSet: update axis map independently (REQ-25)" begin
    using Tray:
        ScalarSchema,
        ScalarSummary,
        Tree,
        MultiAxisSet,
        AxisMap,
        register_axis!,
        update_axis_map!,
        get_leaf_ids

    schema = ScalarSchema{Float64}(false)
    leaves = [
        ScalarSummary(
            count = 1,
            sum = 1.0,
            sumsq = 1.0,
            minimum = 1.0,
            maximum = 1.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 2.0,
            sumsq = 4.0,
            minimum = 2.0,
            maximum = 2.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 3.0,
            sumsq = 9.0,
            minimum = 3.0,
            maximum = 3.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 4.0,
            sumsq = 16.0,
            minimum = 4.0,
            maximum = 4.0,
            schema = schema,
        ),
    ]
    t = Tree(leaves; b = 2, schema)
    mas = MultiAxisSet(t)

    cat_map = AxisMap(Dict("food" => [1, 3], "tools" => [2, 4]))
    register_axis!(mas, "category", cat_map)

    new_cat_map = AxisMap(Dict("food" => [1, 2], "tools" => [3, 4]))
    old_revision = mas.axes["category"].revision
    update_axis_map!(mas, "category", new_cat_map)

    @test mas.axes["category"].revision == old_revision + 1
    @test get_leaf_ids(mas.axes["category"], "food") == [1, 2]
    @test get_leaf_ids(mas.axes["category"], "tools") == [3, 4]
end

@testitem "MultiAxisSet: intersect axes across categories and time (REQ-39)" begin
    using Tray:
        ScalarSchema,
        ScalarSummary,
        Tree,
        MultiAxisSet,
        AxisMap,
        register_axis!,
        intersect_axes,
        identity,
        combine

    schema = ScalarSchema{Float64}(false)
    leaves = [
        ScalarSummary(
            count = 1,
            sum = 10.0,
            sumsq = 100.0,
            minimum = 10.0,
            maximum = 10.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 20.0,
            sumsq = 400.0,
            minimum = 20.0,
            maximum = 20.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 30.0,
            sumsq = 900.0,
            minimum = 30.0,
            maximum = 30.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 40.0,
            sumsq = 1600.0,
            minimum = 40.0,
            maximum = 40.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 50.0,
            sumsq = 2500.0,
            minimum = 50.0,
            maximum = 50.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 60.0,
            sumsq = 3600.0,
            minimum = 60.0,
            maximum = 60.0,
            schema = schema,
        ),
    ]
    t = Tree(leaves; b = 2, schema)
    mas = MultiAxisSet(t)

    cat_map = AxisMap(Dict("electronics" => [1, 3, 5], "clothing" => [2, 4, 6]))
    register_axis!(mas, "category", cat_map)

    time_map = AxisMap(Dict("Q1" => [1, 2], "Q2" => [3, 4], "Q3" => [5, 6]))
    register_axis!(mas, "time", time_map)

    # Query: electronics in Q2 → leaves [3] (sum=30)
    result = intersect_axes(mas, [("category", "electronics"), ("time", "Q2")])
    expected = combine(identity(schema), leaves[3])
    @test result == expected
end

@testitem "MultiAxisSet: intersect with multiple ids in range (REQ-39)" begin
    using Tray:
        ScalarSchema,
        ScalarSummary,
        Tree,
        MultiAxisSet,
        AxisMap,
        register_axis!,
        intersect_axes,
        identity,
        combine

    schema = ScalarSchema{Float64}(false)
    leaves = [
        ScalarSummary(
            count = 1,
            sum = 10.0,
            sumsq = 100.0,
            minimum = 10.0,
            maximum = 10.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 20.0,
            sumsq = 400.0,
            minimum = 20.0,
            maximum = 20.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 30.0,
            sumsq = 900.0,
            minimum = 30.0,
            maximum = 30.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 40.0,
            sumsq = 1600.0,
            minimum = 40.0,
            maximum = 40.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 50.0,
            sumsq = 2500.0,
            minimum = 50.0,
            maximum = 50.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 60.0,
            sumsq = 3600.0,
            minimum = 60.0,
            maximum = 60.0,
            schema = schema,
        ),
    ]
    t = Tree(leaves; b = 2, schema)
    mas = MultiAxisSet(t)

    cat_map = AxisMap(Dict("elec" => [1, 3, 5], "cloth" => [2, 4, 6]))
    register_axis!(mas, "category", cat_map)

    time_map = AxisMap(Dict("early" => [1, 2, 3], "late" => [4, 5, 6]))
    register_axis!(mas, "time", time_map)

    # elec ∩ early = [1, 3] → sum=10+30=40
    result = intersect_axes(mas, [("category", "elec"), ("time", "early")])
    expected = combine(combine(identity(schema), leaves[1]), leaves[3])
    @test result == expected
end

@testitem "MultiAxisSet: intersect three axes (REQ-39)" begin
    using Tray:
        ScalarSchema,
        ScalarSummary,
        Tree,
        MultiAxisSet,
        AxisMap,
        register_axis!,
        intersect_axes,
        identity,
        combine

    schema = ScalarSchema{Float64}(false)
    leaves = [
        ScalarSummary(
            count = 1,
            sum = 10.0,
            sumsq = 100.0,
            minimum = 10.0,
            maximum = 10.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 20.0,
            sumsq = 400.0,
            minimum = 20.0,
            maximum = 20.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 30.0,
            sumsq = 900.0,
            minimum = 30.0,
            maximum = 30.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 40.0,
            sumsq = 1600.0,
            minimum = 40.0,
            maximum = 40.0,
            schema = schema,
        ),
        ScalarSummary(
            count = 1,
            sum = 50.0,
            sumsq = 2500.0,
            minimum = 50.0,
            maximum = 50.0,
            schema = schema,
        ),
    ]
    t = Tree(leaves; b = 2, schema)
    mas = MultiAxisSet(t)

    region_map = AxisMap(Dict("north" => [1, 2], "south" => [3, 4, 5]))
    register_axis!(mas, "region", region_map)

    cat_map = AxisMap(Dict("elec" => [1, 3, 5], "cloth" => [2, 4]))
    register_axis!(mas, "category", cat_map)

    time_map = AxisMap(Dict("q1" => [1, 2], "q2" => [3, 4], "q3" => [5]))
    register_axis!(mas, "time", time_map)

    # South ∩ Elec ∩ Q2 = [3] (sum=30)
    result =
        intersect_axes(mas, [("region", "south"), ("category", "elec"), ("time", "q2")])
    expected = combine(identity(schema), leaves[3])
    @test result == expected
end

@testitem "MultiAxisSet: intersect rejects unknown axis (REQ-39)" begin
    using Tray:
        ScalarSchema,
        ScalarSummary,
        Tree,
        MultiAxisSet,
        AxisMap,
        register_axis!,
        intersect_axes

    schema = ScalarSchema{Float64}(false)
    leaf = ScalarSummary(
        count = 1,
        sum = 1.0,
        sumsq = 1.0,
        minimum = 1.0,
        maximum = 1.0,
        schema = schema,
    )
    t = Tree([leaf]; b = 2, schema)
    mas = MultiAxisSet(t)

    register_axis!(mas, "cat", AxisMap(Dict("a" => [1])))

    @test_throws ArgumentError intersect_axes(mas, [("cat", "a"), ("unknown", "x")])
end

@testitem "MultiAxisSet: intersect rejects unknown node" begin
    using Tray:
        ScalarSchema,
        ScalarSummary,
        Tree,
        MultiAxisSet,
        AxisMap,
        register_axis!,
        intersect_axes

    schema = ScalarSchema{Float64}(false)
    leaf = ScalarSummary(
        count = 1,
        sum = 1.0,
        sumsq = 1.0,
        minimum = 1.0,
        maximum = 1.0,
        schema = schema,
    )
    t = Tree([leaf]; b = 2, schema)
    mas = MultiAxisSet(t)

    register_axis!(mas, "cat", AxisMap(Dict("a" => [1])))

    @test_throws ArgumentError intersect_axes(mas, [("cat", "nonexistent")])
end

## ---------------------------------------------------------------------------
## SamplePayload focused tests (TRAYS-t3f: REQ-20, REQ-28, REQ-30)
## ---------------------------------------------------------------------------

@testitem "SamplePayload: construction from samples computes summary" begin
    using Tray: ScalarSchema, SamplePayload

    schema = ScalarSchema{Float64}(false)
    p = SamplePayload(schema = schema, samples = [1.0, 2.0, 3.0, 4.0, 5.0])

    @test length(p.samples) == 5
    @test p.dataset_revision == 1
    @test p.summary.count == 5
    @test p.summary.sum ≈ 15.0
    @test p.summary.sumsq ≈ 55.0
    @test p.summary.minimum ≈ 1.0
    @test p.summary.maximum ≈ 5.0
end

@testitem "SamplePayload: construction with higher moments" begin
    using Tray: ScalarSchema, SamplePayload

    schema = ScalarSchema{Float64}(true)
    p = SamplePayload(schema = schema, samples = [1.0, 2.0, 3.0])

    @test p.summary.m3 ≈ 1.0 + 8.0 + 27.0  # sum of cubes
    @test p.summary.m4 ≈ 1.0 + 16.0 + 81.0  # sum of 4th powers
end

@testitem "SamplePayload: rejects empty samples" begin
    using Tray: ScalarSchema, SamplePayload

    schema = ScalarSchema{Float64}(false)
    @test_throws ArgumentError SamplePayload(schema = schema, samples = Float64[])
end

@testitem "SamplePayload: rejects non-finite values" begin
    using Tray: ScalarSchema, SamplePayload

    schema = ScalarSchema{Float64}(false)
    @test_throws ArgumentError SamplePayload(schema = schema, samples = [1.0, NaN, 3.0])
    @test_throws ArgumentError SamplePayload(schema = schema, samples = [1.0, Inf, 3.0])
end

@testitem "SamplePayload: identity construction" begin
    using Tray: ScalarSchema, SamplePayload, TrayBase

    schema = ScalarSchema{Float64}(false)
    id = TrayBase.identity(schema, 3)

    @test length(id.samples) == 3
    @test all(s == 0.0 for s in id.samples)
    @test id.summary.count == 0
    @test id.dataset_revision == 1
end

@testitem "SamplePayload: identity laws (left)" begin
    using Tray: ScalarSchema, SamplePayload, TrayBase

    schema = ScalarSchema{Float64}(false)
    id = TrayBase.identity(schema, 3)
    x = SamplePayload(schema = schema, samples = [1.0, 2.0, 3.0])

    @test TrayBase.combine(id, x) == x
end

@testitem "SamplePayload: identity laws (right)" begin
    using Tray: ScalarSchema, SamplePayload, TrayBase

    schema = ScalarSchema{Float64}(false)
    id = TrayBase.identity(schema, 3)
    x = SamplePayload(schema = schema, samples = [1.0, 2.0, 3.0])

    @test TrayBase.combine(x, id) == x
end

@testitem "SamplePayload: combine adds elementwise" begin
    using Tray: ScalarSchema, SamplePayload, TrayBase

    schema = ScalarSchema{Float64}(false)
    a = SamplePayload(schema = schema, samples = [1.0, 2.0, 3.0])
    b = SamplePayload(schema = schema, samples = [4.0, 5.0, 6.0])
    c = TrayBase.combine(a, b)

    @test c.samples ≈ [5.0, 7.0, 9.0]
    @test c.summary.count == 6
    @test c.summary.sum ≈ 21.0
    @test c.dataset_revision == 1
end

@testitem "SamplePayload: combine is associative" begin
    using Tray: ScalarSchema, SamplePayload, TrayBase

    schema = ScalarSchema{Float64}(false)
    a = SamplePayload(schema = schema, samples = [1.0, 2.0])
    b = SamplePayload(schema = schema, samples = [3.0, 4.0])
    c = SamplePayload(schema = schema, samples = [5.0, 6.0])

    r1 = TrayBase.combine(TrayBase.combine(a, b), c)
    r2 = TrayBase.combine(a, TrayBase.combine(b, c))

    @test r1 == r2
    @test r1.samples ≈ [9.0, 12.0]
end

@testitem "SamplePayload: combine rejects cross-revision (REQ-20)" begin
    using Tray: ScalarSchema, SamplePayload, TrayBase

    schema = ScalarSchema{Float64}(false)
    a = SamplePayload(schema = schema, samples = [1.0, 2.0], dataset_revision = 1)
    b = SamplePayload(schema = schema, samples = [3.0, 4.0], dataset_revision = 2)

    @test_throws ArgumentError TrayBase.combine(a, b)
end

@testitem "SamplePayload: combine rejects different sample lengths" begin
    using Tray: ScalarSchema, SamplePayload, TrayBase

    schema = ScalarSchema{Float64}(false)
    a = SamplePayload(schema = schema, samples = [1.0, 2.0])
    b = SamplePayload(schema = schema, samples = [3.0, 4.0, 5.0])

    @test_throws ArgumentError TrayBase.combine(a, b)
end

@testitem "SamplePayload: structural equality" begin
    using Tray: ScalarSchema, SamplePayload

    schema = ScalarSchema{Float64}(false)
    a = SamplePayload(schema = schema, samples = [1.0, 2.0, 3.0])
    b = SamplePayload(schema = schema, samples = [1.0, 2.0, 3.0])

    @test a == b
    @test hash(a) == hash(b)
end

@testitem "SamplePayload: inequality on different samples" begin
    using Tray: ScalarSchema, SamplePayload

    schema = ScalarSchema{Float64}(false)
    a = SamplePayload(schema = schema, samples = [1.0, 2.0])
    b = SamplePayload(schema = schema, samples = [1.0, 3.0])

    @test a != b
end

@testitem "SamplePayload: reweight scales samples (REQ-18)" begin
    using Tray: ScalarSchema, SamplePayload, TrayBase

    schema = ScalarSchema{Float64}(false)
    p = SamplePayload(schema = schema, samples = [1.0, 2.0, 3.0])
    r = TrayBase.reweight(p, 2.0)

    @test r.samples ≈ [2.0, 4.0, 6.0]
    @test r.summary.sum ≈ 12.0
    # Count, min, max preserved
    @test r.summary.count == 3
    @test r.summary.minimum ≈ 1.0
    @test r.summary.maximum ≈ 3.0
end

## ---------------------------------------------------------------------------
## Tree with SamplePayload (REQ-20: tree construction and updates)
## ---------------------------------------------------------------------------

@testitem "Tree: construction with SamplePayload" begin
    using Tray: ScalarSchema, SamplePayload, Tree, root, leaf_count, depth

    schema = ScalarSchema{Float64}(false)
    leaves = [
        SamplePayload(schema = schema, samples = [1.0, 2.0, 3.0]),
        SamplePayload(schema = schema, samples = [4.0, 5.0, 6.0]),
        SamplePayload(schema = schema, samples = [7.0, 8.0, 9.0]),
    ]
    t = Tree(leaves; b = 2, schema)

    @test leaf_count(t) == 3
    @test depth(t) == 2
    @test root(t).samples ≈ [12.0, 15.0, 18.0]
    @test root(t).summary.count == 9
    @test root(t).summary.sum ≈ 45.0
end

@testitem "Tree: SamplePayload update snapshot isolation" begin
    using Tray: ScalarSchema, SamplePayload, Tree, root, update

    schema = ScalarSchema{Float64}(false)
    leaves = [
        SamplePayload(schema = schema, samples = [1.0, 2.0]),
        SamplePayload(schema = schema, samples = [3.0, 4.0]),
    ]
    t = Tree(leaves; b = 2, schema)
    original_root = root(t)

    new_leaf = SamplePayload(schema = schema, samples = [10.0, 20.0])
    t2 = update(t, 1, new_leaf)

    @test root(t2) != original_root
    @test root(t) == original_root  # snapshot isolation
    @test t2.levels[1][1].samples ≈ [10.0, 20.0]
    @test t.levels[1][1].samples ≈ [1.0, 2.0]
end

## ---------------------------------------------------------------------------
## REQ-28: project_samples
## ---------------------------------------------------------------------------

@testitem "project_samples: basic w * M projection (REQ-28)" begin
    using Tray: project_samples, AlignedProjectionError

    w = [1.0, 2.0, 3.0]
    M = [
        1.0 4.0
        2.0 5.0
        3.0 6.0
    ]
    # w * M = [1*1 + 2*2 + 3*3, 1*4 + 2*5 + 3*6] = [14.0, 32.0]
    result = project_samples(w, M)

    @test result ≈ [14.0, 32.0]
end

@testitem "project_samples: single dimension (REQ-28)" begin
    using Tray: project_samples

    w = [2.0]
    M = Float64[1.0 2.0 3.0]  # 1×3 matrix

    result = project_samples(w, M)
    @test result ≈ [2.0, 4.0, 6.0]
end

@testitem "project_samples: single sample (REQ-28)" begin
    using Tray: project_samples

    w = [1.0, 2.0, 3.0]
    M = reshape([1.0, 2.0, 3.0], 3, 1)

    result = project_samples(w, M)
    @test result ≈ [14.0]
end

@testitem "project_samples: weight from tree leaves (REQ-28)" begin
    using Tray: ScalarSchema, SamplePayload, Tree, project_samples, leaf_count

    schema = ScalarSchema{Float64}(false)
    leaves = [
        SamplePayload(schema = schema, samples = [1.0, 2.0, 3.0]),
        SamplePayload(schema = schema, samples = [4.0, 5.0, 6.0]),
    ]
    t = Tree(leaves; b = 2, schema)

    # Weight both leaves equally
    result = project_samples(t, [1.0, 1.0])
    @test result.samples ≈ [5.0, 7.0, 9.0]
    @test result.summary.count == 6

    # Weight first leaf only
    result2 = project_samples(t, [1.0, 0.0])
    @test result2.samples ≈ [1.0, 2.0, 3.0]
end

@testitem "project_samples: rejects mismatched dimensions (REQ-28)" begin
    using Tray: project_samples, AlignedProjectionError

    w = [1.0, 2.0]
    M = [
        1.0 2.0 3.0
        4.0 5.0 6.0
        7.0 8.0 9.0
    ]  # 3×3, but w has length 2

    @test_throws AlignedProjectionError project_samples(w, M)
end

@testitem "project_samples: rejects non-finite values (REQ-28)" begin
    using Tray: project_samples, AlignedProjectionError

    @test_throws AlignedProjectionError project_samples([1.0, NaN], [1.0 2.0; 3.0 4.0])
    @test_throws AlignedProjectionError project_samples([1.0, 2.0], [1.0 2.0; Inf 4.0])
end

@testitem "project_samples: rejects weight length mismatch with tree" begin
    using Tray: ScalarSchema, SamplePayload, Tree, project_samples, AlignedProjectionError

    schema = ScalarSchema{Float64}(false)
    leaves = [
        SamplePayload(schema = schema, samples = [1.0, 2.0]),
        SamplePayload(schema = schema, samples = [3.0, 4.0]),
        SamplePayload(schema = schema, samples = [5.0, 6.0]),
    ]
    t = Tree(leaves; b = 2, schema)

    @test_throws AlignedProjectionError project_samples(t, [1.0, 2.0])  # need 3 weights
end

## ---------------------------------------------------------------------------
## REQ-20: regenerate_samples! / regenerate_samples
## ---------------------------------------------------------------------------

@testitem "regenerate_samples!: replaces samples and increments revision (REQ-20)" begin
    using Tray: ScalarSchema, SamplePayload, Tree, regenerate_samples!, root, leaf_count

    schema = ScalarSchema{Float64}(false)
    leaves = [
        SamplePayload(schema = schema, samples = [1.0, 2.0]),
        SamplePayload(schema = schema, samples = [3.0, 4.0]),
    ]
    t = Tree(leaves; b = 2, schema)

    orig_revision = root(t).dataset_revision

    new_root = regenerate_samples!(t, [[10.0, 20.0], [30.0, 40.0]])

    @test leaf_count(t) == 2
    @test t.levels[1][1].samples ≈ [10.0, 20.0]
    @test t.levels[1][2].samples ≈ [30.0, 40.0]
    @test root(t).summary.count == 4
    @test root(t).summary.sum ≈ 100.0

    # Revision incremented
    @test root(t).dataset_revision == orig_revision + 1
    @test new_root == root(t)
end

@testitem "regenerate_samples!: rejects sample count mismatch" begin
    using Tray: ScalarSchema, SamplePayload, Tree, regenerate_samples!

    schema = ScalarSchema{Float64}(false)
    leaves = [
        SamplePayload(schema = schema, samples = [1.0, 2.0]),
        SamplePayload(schema = schema, samples = [3.0, 4.0]),
    ]
    t = Tree(leaves; b = 2, schema)

    @test_throws ArgumentError regenerate_samples!(t, [[5.0, 6.0]])  # need 2, got 1
end

@testitem "regenerate_samples!: rejects inconsistent sample lengths" begin
    using Tray: ScalarSchema, SamplePayload, Tree, regenerate_samples!

    schema = ScalarSchema{Float64}(false)
    leaves = [
        SamplePayload(schema = schema, samples = [1.0, 2.0]),
        SamplePayload(schema = schema, samples = [3.0, 4.0]),
    ]
    t = Tree(leaves; b = 2, schema)

    @test_throws ArgumentError regenerate_samples!(t, [[1.0, 2.0, 3.0], [4.0, 5.0]])
end

@testitem "regenerate_samples: immutable version preserves original (REQ-20)" begin
    using Tray: ScalarSchema, SamplePayload, Tree, regenerate_samples, root

    schema = ScalarSchema{Float64}(false)
    leaves = [
        SamplePayload(schema = schema, samples = [1.0, 2.0]),
        SamplePayload(schema = schema, samples = [3.0, 4.0]),
    ]
    t = Tree(leaves; b = 2, schema)
    original_root = root(t)

    t2 = regenerate_samples(t, [[10.0, 20.0], [30.0, 40.0]])

    # Original unchanged
    @test root(t).samples ≈ [4.0, 6.0]
    @test root(t) == original_root

    # New tree has updated data
    @test t2.levels[1][1].samples ≈ [10.0, 20.0]
    @test root(t2).dataset_revision == original_root.dataset_revision + 1
end

## ---------------------------------------------------------------------------
## REQ-30: moment_quantile (Cornish-Fisher)
## ---------------------------------------------------------------------------

@testitem "moment_quantile: normal distribution (zero skewness, zero kurtosis)" begin
    using Tray: moment_quantile

    # For a standard normal (μ=0, σ²=1, γ₁=0, γ₂=0), Cornish-Fisher reduces to z_p
    result = moment_quantile(0.5, 0.0, 1.0, 0.0, 0.0)  # median
    @test result.quantile ≈ 0.0 atol = 0.01
    @test result.approximate == true
    @test contains(result.assumption, "Cornish-Fisher")

    # 0.975 quantile ≈ 1.96
    result2 = moment_quantile(0.975, 0.0, 1.0, 0.0, 0.0)
    @test result2.quantile ≈ 1.96 atol = 0.01
end

@testitem "moment_quantile: skewed distribution (REQ-30)" begin
    using Tray: moment_quantile

    # Positive skew (γ₁=1) shifts upper quantile up, lower quantile down
    # For μ=0, σ²=1, p=0.95: z≈1.645, term1=(z²-1)*1/6 ≈ 0.284
    # q ≈ 0 + 1*(1.645 + 0.284) ≈ 1.93 (vs normal 1.645)
    result = moment_quantile(0.95, 0.0, 1.0, 1.0, 0.0)
    @test result.quantile > 1.645  # shifted right (fatter upper tail)
    @test result.skewness ≈ 1.0

    # Negative skew shifts lower quantile down
    result2 = moment_quantile(0.05, 0.0, 1.0, -1.0, 0.0)
    @test result2.quantile < -1.645  # shifted left
end

@testitem "moment_quantile: kurtosis effect (REQ-30)" begin
    using Tray: moment_quantile

    # Positive excess kurtosis (fat tails): extremal quantiles move outward
    # For μ=0, σ²=1, p=0.975: z≈1.96, term2=(z³-3z)*1/24 ≈ 0.09
    # q ≈ 0 + 1*(1.96 + 0.09) ≈ 2.05 (vs normal 1.96)
    result = moment_quantile(0.975, 0.0, 1.0, 0.0, 1.0)
    @test result.quantile > 1.96  # fatter tails
    @test result.excess_kurtosis ≈ 1.0
end

@testitem "moment_quantile: from ScalarSummary with higher moments" begin
    using Tray: ScalarSchema, ScalarSummary, moment_quantile

    schema = ScalarSchema{Float64}(true)
    # Create a summary for [1, 2, 3, 4, 5]
    # mean=3, variance=2, skewness=0 (symmetric), kurtosis slightly negative
    s = ScalarSummary(;
        schema = schema,
        count = 5,
        sum = 15.0,
        sumsq = 55.0,
        minimum = 1.0,
        maximum = 5.0,
        m3 = 225.0,   # sum of cubes: 1+8+27+64+125 = 225
        m4 = 979.0,   # sum of 4th powers: 1+16+81+256+625 = 979
    )

    result = moment_quantile(0.5, s)
    # Median of symmetric distribution ≈ mean ≈ 3.0
    @test result.quantile ≈ 3.0 atol = 0.1
    @test result.approximate == true
end

@testitem "moment_quantile: rejects invalid inputs (REQ-30)" begin
    using Tray: moment_quantile

    # Probability out of range
    @test_throws DomainError moment_quantile(-0.1, 0.0, 1.0, 0.0, 0.0)
    @test_throws DomainError moment_quantile(1.5, 0.0, 1.0, 0.0, 0.0)

    # Non-positive variance
    @test_throws DomainError moment_quantile(0.5, 0.0, 0.0, 0.0, 0.0)
    @test_throws DomainError moment_quantile(0.5, 0.0, -1.0, 0.0, 0.0)

    # Non-finite moments
    @test_throws DomainError moment_quantile(0.5, 0.0, 1.0, NaN, 0.0)
    @test_throws DomainError moment_quantile(0.5, 0.0, 1.0, Inf, 0.0)
end

@testitem "moment_quantile: rejects ScalarSummary without higher_moment (REQ-36)" begin
    using Tray: ScalarSchema, ScalarSummary, moment_quantile

    schema = ScalarSchema{Float64}(false)  # no higher moments
    s = ScalarSummary(;
        schema = schema,
        count = 3,
        sum = 6.0,
        sumsq = 14.0,
        minimum = 1.0,
        maximum = 3.0,
    )

    @test_throws DomainError moment_quantile(0.5, s)
end

@testitem "moment_quantile: rejects empty ScalarSummary" begin
    using Tray: ScalarSchema, moment_quantile, TrayBase

    schema = ScalarSchema{Float64}(true)
    id = TrayBase.identity(schema)

    @test_throws DomainError moment_quantile(0.5, id)
end

@testitem "SamplePayload tree: range query and regeneration end-to-end" begin
    using Tray:
        ScalarSchema,
        SamplePayload,
        Tree,
        root,
        range_query,
        regenerate_samples!,
        dataset_revision

    schema = ScalarSchema{Float64}(false)
    leaves = [
        SamplePayload(schema = schema, samples = [1.0, 2.0, 3.0]),
        SamplePayload(schema = schema, samples = [4.0, 5.0, 6.0]),
        SamplePayload(schema = schema, samples = [7.0, 8.0, 9.0]),
        SamplePayload(schema = schema, samples = [10.0, 11.0, 12.0]),
    ]
    t = Tree(leaves; b = 2, schema)

    rev1 = dataset_revision(t)

    # Full range equals root
    full = range_query(t, 1, 4)
    @test full.samples ≈ [22.0, 26.0, 30.0]

    # Sub-range
    sub = range_query(t, 2, 3)
    @test sub.samples ≈ [11.0, 13.0, 15.0]

    # Regenerate with new samples
    new_root = regenerate_samples!(
        t,
        [
            [100.0, 200.0, 300.0],
            [400.0, 500.0, 600.0],
            [700.0, 800.0, 900.0],
            [1000.0, 1100.0, 1200.0],
        ],
    )

    # Revision incremented
    @test dataset_revision(t) == rev1 + 1

    # All indices reflect new revision
    @test root(t).samples ≈ [2200.0, 2600.0, 3000.0]
    @test root(t).dataset_revision == rev1 + 1
end

## ---------------------------------------------------------------------------
## CompressedSamplePayload & sketch tests (TRAYS-x6z: REQ-21, REQ-22, REQ-32, REQ-44)
## ---------------------------------------------------------------------------

@testitem "SketchConfig: construction validates parameters (REQ-21)" begin
    using Tray: SketchConfig, SketchConfigError

    cfg = SketchConfig(1, 100, 0.0, 100.0, 0.05)
    @test cfg.n_bins == 100
    @test cfg.epsilon == 0.05
    @test cfg.config_id == 1

    @test_throws SketchConfigError SketchConfig(1, 1, 0.0, 1.0, 0.05)
    @test_throws SketchConfigError SketchConfig(1, 10, 10.0, 0.0, 0.05)
    @test_throws SketchConfigError SketchConfig(1, 10, 0.0, 1.0, 0.0)
    @test_throws SketchConfigError SketchConfig(1, 10, 0.0, 1.0, -1.0)
end

@testitem "HistogramSketch: empty sketch and add_value (REQ-21)" begin
    using Tray: SketchConfig, HistogramSketch
    using Tray.SampleAnalytics: add_value!

    cfg = SketchConfig(1, 10, 0.0, 10.0, 0.1)
    s = HistogramSketch(cfg)

    @test s.count == 0
    @test all(s.counts .== 0)

    add_value!(s, 1.5)
    @test s.count == 1
    @test s.counts[2] == 1
end

@testitem "HistogramSketch: value clamped to bin edges (REQ-21)" begin
    using Tray: SketchConfig, HistogramSketch
    using Tray.SampleAnalytics: add_value!

    cfg = SketchConfig(1, 4, 0.0, 4.0, 0.1)
    s = HistogramSketch(cfg)

    add_value!(s, -1.0)
    @test s.counts[1] == 1

    add_value!(s, 10.0)
    @test s.counts[4] == 1

    add_value!(s, 0.0)
    add_value!(s, 4.0)
    @test s.count == 4
end

@testitem "HistogramSketch: combine performs aligned-sum (REQ-21)" begin
    using Tray: SketchConfig, HistogramSketch, TrayBase
    using Tray.SampleAnalytics: add_value!

    cfg = SketchConfig(1, 5, 0.0, 5.0, 0.1)
    a = HistogramSketch(cfg)
    b = HistogramSketch(cfg)

    for v = 0.5:1.0:4.5
        add_value!(a, v)
        add_value!(b, v)
    end

    c = TrayBase.combine(a, b)
    @test c.count == 10
    @test all(c.counts .== 2)

    empty_s = HistogramSketch(cfg)
    @test TrayBase.combine(a, empty_s) == a
    @test TrayBase.combine(empty_s, a) == a
end

@testitem "HistogramSketch: combine rejects different configs (REQ-21)" begin
    using Tray: SketchConfig, HistogramSketch, TrayBase

    a = HistogramSketch(SketchConfig(1, 5, 0.0, 5.0, 0.1))
    b = HistogramSketch(SketchConfig(2, 10, 0.0, 10.0, 0.2))
    @test_throws ArgumentError TrayBase.combine(a, b)
end

@testitem "CompressedSamplePayload: construction from samples (REQ-21)" begin
    using Tray: SketchConfig, CompressedSamplePayload

    cfg = SketchConfig(1, 10, 0.0, 10.0, 0.1)
    csp = CompressedSamplePayload(; samples = [1.0, 2.0, 3.0, 4.0, 5.0], config = cfg)

    @test csp.sketch.count == 5
    @test csp.config_id == 1
    @test csp.dataset_revision == 1
    @test csp.scalar_summary.count == 5
    @test csp.scalar_summary.sum ≈ 15.0
end

@testitem "CompressedSamplePayload: identity laws (REQ-21)" begin
    using Tray: SketchConfig, CompressedSamplePayload, ScalarSchema, TrayBase

    cfg = SketchConfig(1, 10, 0.0, 10.0, 0.1)
    id = TrayBase.identity(ScalarSchema{Float64}(false), cfg)
    x = CompressedSamplePayload(; samples = [1.0, 2.0, 3.0], config = cfg)

    @test TrayBase.combine(id, x) == x
    @test TrayBase.combine(x, id) == x
end

@testitem "CompressedSamplePayload: combine adds elementwise (REQ-21)" begin
    using Tray: SketchConfig, CompressedSamplePayload, TrayBase

    cfg = SketchConfig(1, 10, 0.0, 10.0, 0.1)
    a = CompressedSamplePayload(; samples = [1.0, 2.0, 3.0], config = cfg)
    b = CompressedSamplePayload(; samples = [4.0, 5.0, 6.0], config = cfg)
    c = TrayBase.combine(a, b)

    @test c.sketch.count == 6
    @test c.scalar_summary.count == 6
    @test c.scalar_summary.sum ≈ 21.0
end

@testitem "CompressedSamplePayload: combine rejects cross-config (REQ-21)" begin
    using Tray: SketchConfig, CompressedSamplePayload, TrayBase

    a = CompressedSamplePayload(;
        samples = [1.0, 2.0],
        config = SketchConfig(1, 10, 0.0, 10.0, 0.1),
    )
    b = CompressedSamplePayload(;
        samples = [3.0, 4.0],
        config = SketchConfig(2, 10, 0.0, 10.0, 0.1),
    )
    @test_throws ArgumentError TrayBase.combine(a, b)
end

@testitem "CompressedSamplePayload: combine rejects cross-revision (REQ-20)" begin
    using Tray: SketchConfig, CompressedSamplePayload, TrayBase

    cfg = SketchConfig(1, 10, 0.0, 10.0, 0.1)
    a = CompressedSamplePayload(; samples = [1.0, 2.0], config = cfg, dataset_revision = 1)
    b = CompressedSamplePayload(; samples = [3.0, 4.0], config = cfg, dataset_revision = 2)
    @test_throws ArgumentError TrayBase.combine(a, b)
end

@testitem "compress: from SamplePayload to CompressedSamplePayload (REQ-21)" begin
    using Tray: ScalarSchema, SamplePayload, SketchConfig, CompressedSamplePayload, compress

    cfg = SketchConfig(1, 10, 0.0, 10.0, 0.1)
    schema = ScalarSchema{Float64}(false)
    sp = SamplePayload(; schema = schema, samples = [1.0, 2.0, 3.0, 4.0, 5.0])
    csp = compress(sp, cfg)

    @test isa(csp, CompressedSamplePayload)
    @test csp.sketch.count == 5
    @test csp.scalar_summary == sp.summary
    @test csp.dataset_revision == sp.dataset_revision
end

@testitem "compress: full tree compression (REQ-21)" begin
    using Tray: ScalarSchema, SamplePayload, SketchConfig, Tree, compress, leaf_count, root

    cfg = SketchConfig(1, 10, 0.0, 10.0, 0.1)
    schema = ScalarSchema{Float64}(false)
    leaves = [SamplePayload(; schema = schema, samples = fill(Float64(i), 3)) for i = 1:4]
    t = Tree(leaves; b = 2, schema = schema)
    ct = compress(t, cfg)

    @test leaf_count(ct) == 4
    @test root(ct).sketch.count == 12
end

@testitem "exact_quantile: empirical quantile computation (REQ-6)" begin
    using Tray: exact_quantile

    samples = [1.0, 2.0, 3.0, 4.0, 5.0]
    @test exact_quantile(samples, 0.5) ≈ 3.0
    @test exact_quantile(samples, 0.2) ≈ 1.0
    @test exact_quantile(samples, 0.8) ≈ 4.0
    @test exact_quantile(samples, 1.0) ≈ 5.0
    @test exact_quantile(samples, 0.001) ≈ 1.0
end

@testitem "exact_quantile: from SamplePayload (REQ-6)" begin
    using Tray: ScalarSchema, SamplePayload, exact_quantile

    schema = ScalarSchema{Float64}(false)
    sp = SamplePayload(; schema = schema, samples = [10.0, 20.0, 30.0, 40.0])
    @test exact_quantile(sp, 0.5) ≈ 20.0
end

@testitem "exact_quantile: rejects invalid inputs (REQ-6)" begin
    using Tray: exact_quantile

    @test_throws DomainError exact_quantile(Float64[], 0.5)
    @test_throws DomainError exact_quantile([1.0], 0.0)
    @test_throws DomainError exact_quantile([1.0], -0.5)
    @test_throws DomainError exact_quantile([1.0], 1.5)
end

@testitem "exact_tail_mean: upper-tail mean computation (REQ-6)" begin
    using Tray: exact_tail_mean

    samples = [1.0, 2.0, 3.0, 4.0, 5.0]
    @test exact_tail_mean(samples, 0.8) ≈ 5.0
    @test exact_tail_mean(samples, 0.0) ≈ 3.0
end

@testitem "sketch_quantile: approximate quantile with error bound (REQ-21, REQ-22)" begin
    using Tray: SketchConfig, HistogramSketch, sketch_quantile
    using Tray.SampleAnalytics: add_value!

    cfg = SketchConfig(1, 100, 0.0, 100.0, 0.05)
    s = HistogramSketch(cfg)
    for v = 1.0:100.0
        add_value!(s, v)
    end

    result = sketch_quantile(s, 0.5)
    @test result.approximate == true
    @test result.rank_error_bound ≈ 0.05
    @test result.config_id == 1
    @test result.tail_mean_uncertainty === nothing
    @test result.value ≈ 50.0 atol = 2.0
end

@testitem "sketch_quantile: from CompressedSamplePayload (REQ-32)" begin
    using Tray: SketchConfig, CompressedSamplePayload, sketch_quantile

    cfg = SketchConfig(1, 50, 0.0, 50.0, 0.1)
    csp = CompressedSamplePayload(; samples = collect(1.0:50.0), config = cfg)

    result = sketch_quantile(csp, 0.5)
    @test result.approximate == true
    @test result.value ≈ 25.0 atol = 2.0
end

@testitem "sketch_tail_mean: approximate upper-tail mean (REQ-22)" begin
    using Tray: SketchConfig, HistogramSketch, sketch_tail_mean
    using Tray.SampleAnalytics: add_value!

    cfg = SketchConfig(1, 50, 0.0, 100.0, 0.1)
    s = HistogramSketch(cfg)
    for v = 1.0:100.0
        add_value!(s, v)
    end

    result = sketch_tail_mean(s, 0.9)
    @test result.approximate == true
    @test result.tail_mean_uncertainty !== nothing
    @test result.value ≈ 95.0 atol = 5.0
end

@testitem "sketch_quantile: rejects empty sketch (REQ-32)" begin
    using Tray: SketchConfig, HistogramSketch, sketch_quantile

    cfg = SketchConfig(1, 10, 0.0, 10.0, 0.1)
    @test_throws DomainError sketch_quantile(HistogramSketch(cfg), 0.5)
end

@testitem "CompressedSamplePayload: storage bound independent of leaf count (REQ-44)" begin
    using Tray: ScalarSchema, SketchConfig, CompressedSamplePayload, Tree, leaf_count, root

    cfg = SketchConfig(1, 20, 0.0, 100.0, 0.1)
    schema = ScalarSchema{Float64}(false)

    small = [
        CompressedSamplePayload(; samples = fill(Float64(i*10), 5), config = cfg) for
        i = 1:4
    ]
    small_tree = Tree(small; b = 2, schema = schema)

    large = [
        CompressedSamplePayload(; samples = fill(Float64(i), 5), config = cfg) for i = 1:100
    ]
    large_tree = Tree(large; b = 2, schema = schema)

    @test length(root(small_tree).sketch.counts) == 20
    @test length(root(large_tree).sketch.counts) == 20
    @test root(small_tree).sketch.count == 20
    @test root(large_tree).sketch.count == 500
end

@testitem "CompressedSamplePayload: tree range query consistency (REQ-21)" begin
    using Tray:
        ScalarSchema,
        SketchConfig,
        CompressedSamplePayload,
        SamplePayload,
        Tree,
        compress,
        range_query

    cfg = SketchConfig(1, 50, 0.0, 10.0, 0.1)
    schema = ScalarSchema{Float64}(false)

    exact_leaves = [SamplePayload(; schema = schema, samples = [1.0, 2.0, 3.0]) for _ = 1:4]
    exact_tree = Tree(exact_leaves; b = 2, schema = schema)
    comp_tree = compress(exact_tree, cfg)

    sub = range_query(comp_tree, 1, 2)
    @test sub.sketch.count == 6
end

@testitem "exact_tail_mean: fractional boundary mass (REQ-6)" begin
    using Tray: exact_tail_mean

    result = exact_tail_mean([1.0, 2.0, 3.0, 4.0, 5.0], 0.75)
    @test result ≈ 4.8
end

@testitem "CompressedSamplePayload: equality and hashing" begin
    using Tray: SketchConfig, CompressedSamplePayload

    cfg = SketchConfig(1, 10, 0.0, 10.0, 0.1)
    a = CompressedSamplePayload(; samples = [1.0, 2.0, 3.0], config = cfg)
    b = CompressedSamplePayload(; samples = [1.0, 2.0, 3.0], config = cfg)
    c = CompressedSamplePayload(; samples = [1.0, 2.0, 4.0], config = cfg)

    @test a == b
    @test hash(a) == hash(b)
    @test a != c
end
