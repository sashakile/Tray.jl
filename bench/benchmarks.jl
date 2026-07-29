# Tray.jl — Performance Benchmarks

using Tray
using BenchmarkTools
using LinearAlgebra
using Random

# Seed for reproducibility
Random.seed!(42)

# ── Helpers ─────────────────────────────────────────────────────────────────

function make_scalar_tree(n_leaves::Int, b::Int)
    schema = ScalarSchema{Float64}(false)
    leaves = [
        ScalarSummary(;
            schema,
            count = 1,
            sum_sumsq = (rand(), rand()^2),
            minmax = (0.0, 1.0),
        ) for _ = 1:n_leaves
    ]
    return Tree(leaves; b, schema)
end

# ── Benchmark Cases ─────────────────────────────────────────────────────────

# Case 1: Range query on a mid-sized tree
function bench_range_query(n_leaves::Int = 100_000, b::Int = 32, range_size::Int = 5_000)
    tray = make_scalar_tree(n_leaves, b)
    lo = rand(1:(n_leaves-range_size))
    hi = lo + range_size
    t = @benchmark range_query($tray, $lo, $hi)
    return (
        median_time = minimum(t).time / 1e6,  # ms
        allocs = minimum(t).memory / 1024,    # KiB
        n_leaves = n_leaves,
        b = b,
        range_size = range_size,
    )
end

# Case 2: Point insert
function bench_insert(n_leaves::Int = 100_000, b::Int = 32)
    tray = make_scalar_tree(n_leaves, b)
    schema = ScalarSchema{Float64}(false)
    leaf = ScalarSummary(;
        schema,
        count = 1,
        sum_sumsq = (42.0, 1764.0),
        minmax = (42.0, 42.0),
    )
    idx = rand(1:n_leaves)
    t = @benchmark update($tray, $idx, $leaf)
    return (
        median_time = minimum(t).time / 1e6,
        allocs = minimum(t).memory / 1024,
        n_leaves = n_leaves,
        b = b,
    )
end

# Case 3: Full tree fold
function bench_fold(n_leaves::Int = 100_000, b::Int = 32)
    tray = make_scalar_tree(n_leaves, b)
    t = @benchmark root($tray)
    return (
        median_time = minimum(t).time / 1e6,
        allocs = minimum(t).memory / 1024,
        n_leaves = n_leaves,
        b = b,
    )
end

# Case 4: Construction from leaves
function bench_construct(n_leaves::Int = 100_000, b::Int = 32)
    schema = ScalarSchema{Float64}(false)
    leaves = [
        ScalarSummary(;
            schema,
            count = 1,
            sum_sumsq = (rand(), rand()^2),
            minmax = (0.0, 1.0),
        ) for _ = 1:n_leaves
    ]
    t = @benchmark Tree($leaves; b = $b, schema = $schema)
    return (
        median_time = minimum(t).time / 1e6,
        allocs = minimum(t).memory / 1024,
        n_leaves = n_leaves,
        b = b,
    )
end

# ── Naive O(n) baseline for comparison ──────────────────────────────────────

# Uses leaves collected at construction time for a fair O(n) comparison.
function naive_combine_range(
    leaves::Vector{ScalarSummary{Float64}},
    lo::Int,
    hi::Int,
    schema::ScalarSchema,
)
    result = Tray.identity(schema)
    for i = lo:hi
        result = Tray.combine(result, leaves[i])
    end
    return result
end

function bench_naive_range(n_leaves::Int = 100_000, range_size::Int = 5_000)
    schema = ScalarSchema{Float64}(false)
    leaves = [
        ScalarSummary(;
            schema,
            count = 1,
            sum_sumsq = (rand(), rand()^2),
            minmax = (0.0, 1.0),
        ) for _ = 1:n_leaves
    ]
    lo = rand(1:(n_leaves-range_size))
    hi = lo + range_size
    t = @benchmark naive_combine_range($leaves, $lo, $hi, $schema)
    return (
        median_time = minimum(t).time / 1e6,
        n_leaves = n_leaves,
        range_size = range_size,
    )
end

# ── Runner ──────────────────────────────────────────────────────────────────

function run_all()
    println("="^60)
    println("Tray.jl Benchmarks")
    println("="^60)

    println("\n── Range query (100K leaves, b=32, 5K range) ──")
    r = bench_range_query()
    range_ms = r.median_time
    println("  Median: $(range_ms) ms, Allocs: $(r.allocs) KiB")

    println("\n── Naive O(n) range (100K leaves, 5K range) ──")
    r2 = bench_naive_range()
    naive_ms = r2.median_time
    println("  Median: $(naive_ms) ms")
    if naive_ms > 0
        println("  Speedup vs naive: $(round(naive_ms / range_ms, digits=2))×")
    end

    println("\n── Point insert (100K leaves, b=32) ──")
    r3 = bench_insert()
    println("  Median: $(r3.median_time) ms, Allocs: $(r3.allocs) KiB")

    println("\n── Full tree root access (100K leaves, b=32) ──")
    r4 = bench_fold()
    println("  Median: $(r4.median_time) ms, Allocs: $(r4.allocs) KiB")

    println("\n── Construction (100K leaves, b=32) ──")
    r5 = bench_construct()
    println("  Median: $(r5.median_time) ms, Allocs: $(r5.allocs) KiB")

    println("\n✓ Benchmarks complete")
end

if abspath(PROGRAM_FILE) == @__FILE__
    run_all()
end
