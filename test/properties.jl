# ── Supposition property-based test integration (TRAYS-nyc) ──────────────────
#
# This file is intentionally NOT named *_test.jl or *_tests.jl so that
# ReTestItems does not discover it as a worker file. It is explicitly included
# from test/runtests.jl inside an ordinary top-level Test.@testset.
#
# See docs/src/dev/testing.md for placement rules and future-runner migration
# guidance.
#
# Conventions for splitting (when this file exceeds ~200 lines or 10 properties):
# - Create test/properties/<topic>.jl for each group of related properties.
# - Include the new file from this file, inside the same outer @testset.
# - Keep shared generator types in test/helpers/. Currently TestTokenPayload
#   lives in test/helpers/TokenPayload.jl.

using Random: MersenneTwister
using Supposition
using Test

include("helpers/TokenPayload.jl")
using .TestTokenPayload: TokenSchema, TokenPayload

@testset "Supposition integration smoke" begin
    # Deterministic, bounded smoke property: verifies that Supposition is
    # available, that @check works inside an ordinary @testset, and that
    # Tray APIs are accessible from the property file.
    @check rng = MersenneTwister(42) max_examples = 100 db = false function smoke_tray_integration(
        x = Data.Integers(1, 100),
    )
        Tray.TrayBase.identity(Tray.ScalarSchema{Float64}(false)).count == 0 && x > 0
    end
end

# ── Noncommutative TokenPayload for tree ordering tests (TRAYS-nyc.2) ─────────
#
# TokenSchema, TokenPayload, and their TrayBase method implementations live
# in test/helpers/TokenPayload.jl (TestTokenPayload module).

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
    # Worst-case depth: b=2, n=32 → depth=5.
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

# ── Persistent-update equivalence and isolation (TRAYS-nyc.4) ───────────────
#
# Independent oracle: manually rebuild the tree with the replaced leaf and
# compare b, schema, and levels. Snapshot original levels to verify isolation.

@testset "Persistent update equivalence (TRAYS-nyc.4)" begin
    # Property: for any n ∈ [1, 32], b ∈ [2, 8], and valid index, a persistent
    # update produces a tree with equal b, schema, and levels to an independent
    # rebuild, while the original tree's levels remain unchanged.
    # Uses distinct token values for each leaf so that ancestor-path recomputation
    # is exercised (not just identity-leaf replacement).
    @check rng = MersenneTwister(42) max_examples = 100 db = false function persistent_update_equals_rebuild(
        n = Data.Integers(1, 32),
        b = Data.Integers(2, 8),
        idx = Data.Integers(1, 32),
    )
        idx = min(idx, n)
        leaves = [TokenPayload{Int}([t]) for t = 1:n]
        tree = Tray.Tree(leaves; b = b, schema = TokenSchema())
        original_levels = deepcopy(tree.levels)
        updated_tree = Tray.update(tree, idx, TokenPayload{Int}([999]))
        rebuilt_leaves = copy(leaves)
        rebuilt_leaves[idx] = TokenPayload{Int}([999])
        rebuilt_tree = Tray.Tree(rebuilt_leaves; b = b, schema = TokenSchema())
        return (updated_tree.b == rebuilt_tree.b) &
               (updated_tree.schema == rebuilt_tree.schema) &
               (updated_tree.levels == rebuilt_tree.levels) &
               (tree.levels == original_levels)
    end
end
