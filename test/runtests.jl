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
