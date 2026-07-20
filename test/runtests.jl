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
