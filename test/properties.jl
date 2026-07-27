# ── Supposition property-based test integration (TRAYS-nyc.1) ────────────────
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
    # small integers. This verifies that Supposition is available, that @check
    # works inside an ordinary @testset, and that failures propagate through
    # Pkg.test().
    @check rng = MersenneTwister(42) max_examples = 100 db = false function smoke_addition_is_commutative(
        x = Data.Integers(1, 100),
        y = Data.Integers(1, 100),
    )
        x + y == y + x
    end
end
