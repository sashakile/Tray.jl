# ── Supposition property-based test integration (TRAYS-nyc.1, TRAYS-nyc.2) ────
#
# This file is intentionally NOT named *_test.jl or *_tests.jl so that
# ReTestItems does not discover it as a worker file. It is explicitly included
# from test/runtests.jl inside an ordinary top-level Test.@testset.
#
# See docs/src/dev/testing.md for placement rules and future-runner migration
# guidance.

using Random: MersenneTwister
using Supposition
using Test

@testset "Supposition integration smoke" begin
    # Deterministic, bounded smoke property: commutativity of addition for
    # small integers.
    @check rng = MersenneTwister(42) max_examples = 100 db = false function smoke_addition_is_commutative(
        x = Data.Integers(1, 100),
        y = Data.Integers(1, 100),
    )
        x + y == y + x
    end
end

# ── Noncommutative TokenPayload for tree ordering tests (TRAYS-nyc.2) ─────────
#
# A simple position-distinct payload: each leaf carries a unique integer token.
# combine concatenates tokens in order (noncommutative), so the root's token
# sequence equals the original leaf token vector — an independent oracle.

struct TokenSchema end

struct TokenPayload{T}
    tokens::Vector{T}
end

Base.:(==)(a::TokenPayload, b::TokenPayload) = a.tokens == b.tokens
Base.hash(a::TokenPayload, h::UInt) = hash(a.tokens, h)

function Tray.TrayBase.identity(::TokenSchema)
    return TokenPayload{Int}(Int[])
end

function Tray.TrayBase.combine(a::TokenPayload{Int}, b::TokenPayload{Int})
    return TokenPayload{Int}(vcat(a.tokens, b.tokens))
end

function Tray.TrayBase.identity(
    ::TokenSchema,
    ::Type{TokenPayload{Int}},
    prototype::TokenPayload{Int},
)
    return Tray.TrayBase.identity(TokenSchema())
end

# ── Generators (Task 2.1) ────────────────────────────────────────────────────
#
# Bounded scenario generators that construct valid dependent tree sizes,
# branching factors, ranges, and position-distinct token payloads without
# rejection-heavy filtering.

@testset "Root token ordering (TRAYS-nyc.2)" begin
    # Property: for any n ∈ [1, 32] and b ∈ [2, 8], a tree with position-distinct
    # tokens has root token sequence equal to the raw leaf token vector.
    @check rng = MersenneTwister(42) max_examples = 100 db = false function root_equals_token_vector(
        n = Data.Integers(1, 32),
        b = Data.Integers(2, 8),
    )
        tokens = collect(1:n)
        leaves = [TokenPayload{Int}([t]) for t in tokens]
        t = Tray.Tree(leaves; b = b, schema = TokenSchema())
        Tray.root(t).tokens == tokens
    end
end

@testset "Range query token ordering (TRAYS-nyc.2)" begin
    # Property: for any n ∈ [1, 32], b ∈ [2, 8], and valid lo ≤ hi,
    # a range query returns the exact token slice in left-to-right order.
    @check rng = MersenneTwister(42) max_examples = 100 db = false function range_query_equals_token_slice(
        n = Data.Integers(1, 32),
        b = Data.Integers(2, 8),
        lo = Data.Integers(1, 32),
        hi = Data.Integers(1, 32),
    )
        # Ensure lo ≤ hi ≤ n by construction (no rejection)
        lo = min(lo, hi, n)
        hi = min(max(lo, hi), n)
        tokens = collect(1:n)
        leaves = [TokenPayload{Int}([t]) for t in tokens]
        t = Tray.Tree(leaves; b = b, schema = TokenSchema())
        Tray.range_query(t, lo, hi).tokens == tokens[lo:hi]
    end
end

# ── Exact depth integer recurrence (TRAYS-nyc.3) ────────────────────────────
#
# Independent oracle: repeated cld(remaining, b) until one leaf remains.
# This is exact — no floating logarithms, no ±1 tolerance.

function exact_depth_oracle(n::Int, b::Int)
    remaining = n
    steps = 0
    while remaining > 1
        remaining = cld(remaining, b)
        steps += 1
    end
    return steps
end

@testset "Exact tree depth (TRAYS-nyc.3)" begin
    # Property: for any n ∈ [1, 32] and b ∈ [2, 8], a tree's depth equals the
    # number of repeated cld(remaining, b) steps needed to reduce n to 1.
    # This covers all n, not just powers of b (stronger than existing O(log_b n) test).
    @check rng = MersenneTwister(42) max_examples = 100 db = false function exact_depth_property(
        n = Data.Integers(1, 32),
        b = Data.Integers(2, 8),
    )
        schema = Tray.ScalarSchema{Float64}(false)
        id = Tray.TrayBase.identity(schema)
        leaves = [id for _ = 1:n]
        t = Tray.Tree(leaves; b = b, schema = schema)
        Tray.depth(t) == exact_depth_oracle(n, b)
    end
end
