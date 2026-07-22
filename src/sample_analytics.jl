"""
    Tray.SampleAnalytics

Sample analytics layer: sample payloads, dataset revision management,
matrix projection, and moment-based quantile estimation.

Exports:
- `SamplePayload` — a tree payload wrapping `ScalarSummary` with a sample vector
- `project_samples` — aligned-array-by-matrix projection (REQ-28)
- `moment_quantile` — Cornish-Fisher moment-based quantile estimate (REQ-30)
- `regenerate_samples!` — replace leaf samples and create new revision (REQ-20)
- `regenerate_samples` — immutable version of regeneration
- `dataset_revision` — extract revision from a SamplePayload tree
- `AlignedProjectionError` — thrown on misaligned projection inputs
- `MomentQuantileResult` — result struct for moment-based quantile
"""
module SampleAnalytics

import ..TrayBase
import ..Tray: ScalarSchema, ScalarSummary, Tree, leaf_count, depth, root

export SamplePayload,
    project_samples,
    moment_quantile,
    regenerate_samples!,
    regenerate_samples,
    dataset_revision,
    AlignedProjectionError,
    MomentQuantileResult

# ---------------------------------------------------------------------------
# Dataset revision constant
# ---------------------------------------------------------------------------

const INITIAL_REVISION = 1

# ---------------------------------------------------------------------------
# SamplePayload
# ---------------------------------------------------------------------------

"""
    SamplePayload{T}

A tree payload wrapping a `ScalarSummary` with an aligned sample vector
of length `S`. The sample vector stores the actual sample values alongside
the scalar aggregates (count, sum, sumsq, etc.) for fast scalar queries.

- `summary` — `ScalarSummary` derived from the sample values
- `samples::Vector{T}` — the sample vector (length S, finite values)
- `dataset_revision` — revision counter for dataset regeneration tracking

Two SamplePayloads can only be combined when they have the same sample length
and the same dataset revision. Cross-revision combination raises an error
(REQ-20: "Different revisions SHALL NOT combine in one query").

See REQ-20, REQ-36.
"""
struct SamplePayload{T}
    summary::ScalarSummary{T}
    samples::Vector{T}
    dataset_revision::Int

    function SamplePayload{T}(
        summary::ScalarSummary{T},
        samples::Vector{T},
        dataset_revision::Int = INITIAL_REVISION,
    ) where {T}
        # Validate sample vector non-empty
        isempty(samples) && throw(ArgumentError("SamplePayload: samples must be non-empty"))

        # Validate all sample values are finite
        all(isfinite, samples) ||
            throw(ArgumentError("SamplePayload: all sample values must be finite"))

        # For identity (count=0), samples must be all zeros
        if summary.count == 0
            all(iszero, samples) || throw(
                ArgumentError(
                    "SamplePayload: identity payload must have zero-valued samples, " *
                    "got $samples",
                ),
            )
        end

        return new{T}(summary, samples, dataset_revision)
    end
end

"""
    SamplePayload(; schema, samples, dataset_revision)

Convenience keyword constructor. Computes the `ScalarSummary` from samples.
"""
function SamplePayload(;
    schema::ScalarSchema{T},
    samples::Vector{T},
    dataset_revision::Int = INITIAL_REVISION,
) where {T}
    isempty(samples) && throw(ArgumentError("SamplePayload: samples must be non-empty"))
    all(isfinite, samples) ||
        throw(ArgumentError("SamplePayload: all sample values must be finite"))

    count = length(samples)
    s = sum(samples)
    sq = sum(x -> x^2, samples)
    mn = minimum(samples)
    mx = maximum(samples)

    summary = ScalarSummary(;
        schema = schema,
        count = count,
        sum = s,
        sumsq = sq,
        minimum = mn,
        maximum = mx,
        m3 = schema.higher_moment ? sum(x -> x^3, samples) : zero(T),
        m4 = schema.higher_moment ? sum(x -> x^4, samples) : zero(T),
    )

    return SamplePayload{T}(summary, samples, dataset_revision)
end

# Inner constructor with positional args
function SamplePayload(
    schema::ScalarSchema{T},
    samples::Vector{T},
    dataset_revision::Int = INITIAL_REVISION,
) where {T}
    return SamplePayload(;
        schema = schema,
        samples = samples,
        dataset_revision = dataset_revision,
    )
end

# ---------------------------------------------------------------------------
# Dataset revision accessors
# ---------------------------------------------------------------------------

"""
    dataset_revision(payload::SamplePayload) -> Int

Extract the dataset revision from a SamplePayload.
"""
dataset_revision(payload::SamplePayload) = payload.dataset_revision

"""
    dataset_revision(tree::Tree{<:SamplePayload}) -> Int

Extract the dataset revision from a SamplePayload tree's root.
"""
dataset_revision(tree::Tree{<:SamplePayload}) = dataset_revision(root(tree))

"""
    identity(schema::ScalarSchema{T}, sample_length::Int) -> SamplePayload{T}

Return the identity SamplePayload for the given schema and sample length.
The identity has zero summary and zero-valued samples.
"""
function TrayBase.identity(schema::ScalarSchema{T}, sample_length::Int) where {T}
    sample_length >= 0 ||
        throw(ArgumentError("sample_length must be ≥ 0, got $sample_length"))
    if sample_length == 0
        # Empty identity (used when no samples available)
        summary = TrayBase.identity(schema)
        return SamplePayload{T}(summary, T[], INITIAL_REVISION)
    end
    summary = TrayBase.identity(schema)
    samples = zeros(T, sample_length)
    return SamplePayload{T}(summary, samples, INITIAL_REVISION)
end

"""
    TrayBase.identity(schema::ScalarSchema{T}, ::Type{SamplePayload{T}}, prototype::SamplePayload{T}) -> SamplePayload{T}

Return the identity SamplePayload for the given schema and payload type,
using `prototype` to determine the sample length and dataset revision.
"""
function TrayBase.identity(
    schema::ScalarSchema{T},
    ::Type{SamplePayload{T}},
    prototype::SamplePayload{T},
) where {T}
    summary = TrayBase.identity(schema)
    samples = zeros(T, length(prototype.samples))
    return SamplePayload{T}(summary, samples, prototype.dataset_revision)
end

"""
    combine(a::SamplePayload{T}, b::SamplePayload{T}) -> SamplePayload{T}

Elementwise combination: scalar summaries combine per ScalarSummary rules;
sample vectors are added elementwise.

REQ-20 constraint: raises `ArgumentError` if dataset revisions differ
(different revisions SHALL NOT combine in one query).

Raises `ArgumentError` if sample vectors have different lengths.
"""
function TrayBase.combine(a::SamplePayload{T}, b::SamplePayload{T}) where {T}
    # Reject cross-revision combination (REQ-20)
    if a.dataset_revision != b.dataset_revision
        throw(
            ArgumentError(
                "SamplePayload: cannot combine payloads with different dataset " *
                "revisions ($(a.dataset_revision) vs $(b.dataset_revision)); " *
                "all samples in a query must share the same revision (REQ-20)",
            ),
        )
    end

    # Validate sample lengths match
    if length(a.samples) != length(b.samples)
        throw(
            ArgumentError(
                "SamplePayload: cannot combine payloads with different sample " *
                "lengths ($(length(a.samples)) vs $(length(b.samples))",
            ),
        )
    end

    combined_summary = TrayBase.combine(a.summary, b.summary)
    combined_samples = a.samples .+ b.samples

    return SamplePayload{T}(combined_summary, combined_samples, a.dataset_revision)
end

# Fallback for mismatched types
function TrayBase.combine(a::SamplePayload, b::SamplePayload)
    throw(
        ArgumentError(
            "SamplePayload alignment error: cannot combine type $(typeof(a)) with $(typeof(b))",
        ),
    )
end

"""
    reweight(payload::SamplePayload{T}, weight::Number) -> SamplePayload{T}

Scale sample values by `weight`. Count, minimum, and maximum are preserved
unchanged. The scalar summary is also reweighted.

Weight must be ≥ 0. Weight 1.0 is the identity.

See REQ-18, REQ-29.
"""
function TrayBase.reweight(payload::SamplePayload{T}, weight::Number) where {T}
    weight >= 0 || throw(ArgumentError("reweight: weight must be ≥ 0, got $weight"))

    reweighted_summary = TrayBase.reweight(payload.summary, weight)
    reweighted_samples = payload.samples .* weight

    return SamplePayload{T}(
        reweighted_summary,
        reweighted_samples,
        payload.dataset_revision,
    )
end

# ---------------------------------------------------------------------------
# Structural equality
# ---------------------------------------------------------------------------

function Base.:(==)(a::SamplePayload{T}, b::SamplePayload{T}) where {T}
    return a.summary == b.summary &&
           a.samples == b.samples &&
           a.dataset_revision == b.dataset_revision
end
Base.:(==)(a::SamplePayload, b::SamplePayload) = false

function Base.hash(a::SamplePayload{T}, h::UInt) where {T}
    return hash(a.summary, hash(a.samples, hash(a.dataset_revision, h)))
end

function Base.show(io::IO, p::SamplePayload{T}) where {T}
    print(
        io,
        "SamplePayload{$T}(",
        length(p.samples),
        " samples, rev=",
        p.dataset_revision,
        ", sum=",
        p.summary.sum,
        ")",
    )
end

# ---------------------------------------------------------------------------
# REQ-28: Aligned matrix projection
# ---------------------------------------------------------------------------

"""
    AlignedProjectionError <: Exception

Thrown on misaligned matrix projection inputs (REQ-28).

See `project_samples`.
"""
struct AlignedProjectionError <: Exception
    message::String
end

Base.showerror(io::IO, e::AlignedProjectionError) =
    print(io, "AlignedProjectionError: ", e.message)

"""
    project_samples(w::Vector{T}, M::Matrix{T}) -> Vector{T}

Generic aligned-array-by-matrix sample projection (REQ-28).

Computes `w * M` where:
- `w` is a row vector of length K (weight vector for dimension IDs)
- `M` is a finite K × S matrix (dimensions × samples)

The result is a length-S sample vector. All values must be finite.

Raises `AlignedProjectionError` if:
- Dimensions are incompatible (length(w) != size(M, 1))
- Any value is non-finite (NaN, Inf)

See REQ-28.
"""
function project_samples(w::Vector{T}, M::Matrix{T}) where {T}
    K = length(w)
    K == size(M, 1) || throw(
        AlignedProjectionError(
            "weight vector length ($K) must match matrix row count ($(size(M, 1))",
        ),
    )

    # Validate finite values
    all(isfinite, w) || throw(AlignedProjectionError("all weight values must be finite"))
    all(isfinite, M) || throw(AlignedProjectionError("all matrix values must be finite"))

    return vec(w' * M)
end

"""
    project_samples(tree::Tree{<:SamplePayload{T}}, w::Vector{T}) -> SamplePayload{T}

Project the aligned leaf sample matrix by weight vector `w`.
Each leaf's sample vector is weighted by the corresponding element of `w`,
and the result is folded into a single SamplePayload.

More precisely: if the tree has N leaves, each with sample vector s_i (length S),
then `w` must have length N. The result is Σ w_i * s_i as a SamplePayload.

Raises `AlignedProjectionError` if `w` length doesn't match leaf count.
"""
function project_samples(tree::Tree{<:SamplePayload{T}}, w::Vector{T}) where {T}
    n = leaf_count(tree)
    length(w) == n || throw(
        AlignedProjectionError(
            "weight vector length ($(length(w))) must match leaf count ($n)",
        ),
    )

    all(isfinite, w) || throw(AlignedProjectionError("all weight values must be finite"))

    # Get sample length from first leaf
    first_leaf = tree.levels[1][1]
    S = length(first_leaf.samples)
    schema = first_leaf.summary.schema

    # Accumulate weighted samples
    combined_samples = zeros(T, S)
    combined_summary = TrayBase.identity(schema)
    revision = first_leaf.dataset_revision

    for i = 1:n
        leaf = tree.levels[1][i]
        w_i = w[i]

        # Validate revision consistency
        if leaf.dataset_revision != revision
            throw(
                ArgumentError(
                    "project_samples: leaf $i has revision $(leaf.dataset_revision) " *
                    "but expected $revision; all leaves must share the same revision",
                ),
            )
        end

        # Weighted contribution
        combined_samples .+= w_i .* leaf.samples

        # For the scalar summary, we reweight the leaf summary and combine
        weighted_leaf = TrayBase.reweight(leaf.summary, w_i)
        combined_summary = TrayBase.combine(combined_summary, weighted_leaf)
    end

    return SamplePayload{T}(combined_summary, combined_samples, revision)
end

# ---------------------------------------------------------------------------
# REQ-20: Sample regeneration
# ---------------------------------------------------------------------------

"""
    regenerate_samples!(tree::Tree{SamplePayload{T}}, new_samples::Vector{Vector{T}}) -> SamplePayload{T}

Replace all leaf sample data with `new_samples` and create a new dataset revision.

- `tree` is mutated in-place: all leaf SamplePayloads are replaced
- All internal nodes are recomputed bottom-up
- The dataset revision is incremented globally (all leaves get the same new revision)
- Returns the new root

Each element of `new_samples` corresponds to a leaf (order must match).
Each sample vector must have the same length.

Raises `ArgumentError` if:
- `new_samples` length doesn't match leaf count
- Sample vectors have inconsistent lengths
- Any sample contains non-finite values

See REQ-20.
"""
function regenerate_samples!(
    tree::Tree{SamplePayload{T}},
    new_samples::Vector{Vector{T}},
) where {T}
    n = leaf_count(tree)
    length(new_samples) == n || throw(
        ArgumentError(
            "regenerate_samples!: expected $n sample vectors, got $(length(new_samples))",
        ),
    )

    # Validate all sample vectors are consistent
    S = length(new_samples[1])
    S > 0 || throw(ArgumentError("regenerate_samples!: sample vectors must be non-empty"))

    new_revision = tree.levels[1][1].dataset_revision + 1
    schema = tree.levels[1][1].summary.schema

    # Validate and create new leaf payloads
    new_leaves = Vector{SamplePayload{T}}(undef, n)
    for i = 1:n
        samples = new_samples[i]
        length(samples) == S || throw(
            ArgumentError(
                "regenerate_samples!: leaf $i has sample length $(length(samples)) " *
                "but expected $S",
            ),
        )

        new_leaves[i] = SamplePayload(;
            schema = schema,
            samples = samples,
            dataset_revision = new_revision,
        )
    end

    # Replace leaves
    tree.levels[1] = new_leaves

    # Rebuild all internal levels bottom-up
    current = tree.levels[1]
    for level_idx = 2:length(tree.levels)
        next_level = tree.levels[level_idx]
        child_start = 1
        for i in eachindex(next_level)
            chunk = current[child_start:min(child_start+tree.b-1, end)]
            next_level[i] = reduce(TrayBase.combine, chunk)
            child_start += tree.b
        end
        current = next_level
    end

    return root(tree)
end

"""
    regenerate_samples(tree::Tree{SamplePayload{T}}, new_samples::Vector{Vector{T}}) -> Tree{SamplePayload{T}}

Immutable version of sample regeneration.
Returns a new tree with updated samples and incremented dataset revision.
The original tree is unchanged.

See REQ-20.
"""
function regenerate_samples(
    tree::Tree{SamplePayload{T}},
    new_samples::Vector{Vector{T}},
) where {T}
    n = leaf_count(tree)
    length(new_samples) == n || throw(
        ArgumentError(
            "regenerate_samples: expected $n sample vectors, got $(length(new_samples))",
        ),
    )

    S = length(new_samples[1])
    S > 0 || throw(ArgumentError("regenerate_samples: sample vectors must be non-empty"))

    new_revision = tree.levels[1][1].dataset_revision + 1
    schema = tree.levels[1][1].summary.schema

    # Build new leaf level
    new_levels = [Vector{SamplePayload{T}}(undef, n)]
    for i = 1:n
        samples = new_samples[i]
        length(samples) == S || throw(
            ArgumentError(
                "regenerate_samples: leaf $i has sample length $(length(samples)) " *
                "but expected $S",
            ),
        )

        new_levels[1][i] = SamplePayload(;
            schema = schema,
            samples = samples,
            dataset_revision = new_revision,
        )
    end

    # Build internal levels bottom-up
    current = new_levels[1]
    for level_idx = 2:length(tree.levels)
        next_level = Vector{SamplePayload{T}}(undef, length(tree.levels[level_idx]))
        child_start = 1
        for i in eachindex(next_level)
            chunk = current[child_start:min(child_start+tree.b-1, end)]
            next_level[i] = reduce(TrayBase.combine, chunk)
            child_start += tree.b
        end
        push!(new_levels, next_level)
        current = next_level
    end

    return Tree{SamplePayload{T},typeof(tree.schema)}(tree.b, new_levels, tree.schema)
end

# ---------------------------------------------------------------------------
# REQ-30: Moment-based quantile estimate (Cornish-Fisher)
# ---------------------------------------------------------------------------

"""
    MomentQuantileResult{T}

Result of a moment-based quantile estimate (Cornish-Fisher expansion).

- `quantile` — the estimated quantile value
- `approximate::Bool` — always `true` (the estimate is inherently approximate)
- `p` — the requested probability
- `mean` — the population mean used
- `variance` — the population variance used
- `skewness` — the skewness (γ₁) used
- `excess_kurtosis` — the excess kurtosis (γ₂) used
- `assumption::String` — describes the near-Gaussian assumption

See REQ-30.
"""
struct MomentQuantileResult{T}
    quantile::T
    approximate::Bool
    p::T
    mean::T
    variance::T
    skewness::T
    excess_kurtosis::T
    assumption::String
end

function Base.show(io::IO, r::MomentQuantileResult)
    print(
        io,
        "MomentQuantileResult($(r.quantile), p=$(r.p), approx=$(r.approximate), " *
        "assumption=\"$(r.assumption)\")",
    )
end

# Normal quantile using Acklam rational approximation (accurate to ~1.5e-8)
# Well-conditioned for all p in (0, 1).
function _normal_quantile(p::T) where {T<:AbstractFloat}
    p <= 0 && return -T(Inf)
    p >= 1 && return T(Inf)

    # Use symmetry: compute for p >= 0.5
    if p < 0.5
        return -_normal_quantile(1 - p)
    end

    # Constants for Acklam approximation
    a0 = T(2.50662823884)
    a1 = T(-18.61500062529)
    a2 = T(41.39119773534)
    a3 = T(-25.44106049637)
    b1 = T(-8.47351093090)
    b2 = T(23.08336743743)
    b3 = T(-21.06224101826)
    b4 = T(3.13082909833)
    c0 = T(-2.78718931138)
    c1 = T(-2.29796479134)
    c2 = T(4.85014127135)
    c3 = T(2.32121276858)
    d1 = T(3.54388924762)
    d2 = T(1.63706781897)

    q = p - T(0.5)

    if abs(q) <= T(0.42)
        # Central region: rational approximation
        r = q * q
        result =
            q * (((a3 * r + a2) * r + a1) * r + a0) /
            ((((b4 * r + b3) * r + b2) * r + b1) * r + 1)
        return result
    end

    # Tail region
    r = p
    if q > 0
        r = 1 - p
    end
    r = sqrt(-log(r))
    result = (((c3 * r + c2) * r + c1) * r + c0) / ((d2 * r + d1) * r + 1)
    return result
end

# Fallback for non-AbstractFloat types
function _normal_quantile(p::T) where {T}
    result = _normal_quantile(Float64(p))
    return T(result)
end

"""
    moment_quantile(p::Real, mean::Real, variance::Real, skewness::Real, excess_kurtosis::Real) -> MomentQuantileResult

Estimate a quantile using the Cornish-Fisher expansion (REQ-30).

The Cornish-Fisher expansion approximates a quantile using the first four moments:
    q(p) ≈ μ + σ * z_p + σ * [(z_p² - 1)γ₁/6 + (z_p³ - 3z_p)γ₂/24 - (2z_p³ - 5z_p)γ₁²/36]

Where:
- `p` — probability in (0, 1)
- `mean` (μ) — population mean
- `variance` (σ²) — population variance (must be positive)
- `skewness` (γ₁) — population skewness (third standardized moment)
- `excess_kurtosis` (γ₂) — population excess kurtosis (fourth standardized moment − 3)
- `z_p` — standard normal quantile at p

Returns a `MomentQuantileResult{T}` with:
- The estimated quantile value
- `approximate = true` (the estimate is inherently approximate)
- The near-Gaussian assumption documented

Raises `DomainError` if:
- `p` is not in (0, 1)
- `variance` is non-positive
- `skewness` or `excess_kurtosis` are non-finite (NaN or Inf)

See REQ-30.
"""
function moment_quantile(
    p::Real,
    mean::Real,
    variance::Real,
    skewness::Real,
    excess_kurtosis::Real,
)
    # Coerce to a common float type
    T = promote_type(
        typeof(mean),
        typeof(variance),
        typeof(skewness),
        typeof(excess_kurtosis),
    )
    T_float = float(T)

    p_f = float(p)
    μ = T_float(mean)
    σ² = T_float(variance)
    γ₁ = T_float(skewness)
    γ₂ = T_float(excess_kurtosis)

    # Validate probability
    0 < p_f < 1 || throw(DomainError(p_f, "moment_quantile: probability must be in (0, 1)"))

    # Validate variance is positive
    σ² > 0 || throw(DomainError(σ², "moment_quantile: variance must be positive"))

    # Validate finite moments
    isfinite(γ₁) || throw(DomainError(γ₁, "moment_quantile: skewness must be finite"))
    isfinite(γ₂) ||
        throw(DomainError(γ₂, "moment_quantile: excess_kurtosis must be finite"))

    σ = sqrt(σ²)
    z = _normal_quantile(p_f)

    # Cornish-Fisher expansion:
    # q(p) ≈ μ + σ * [z + (z² - 1)γ₁/6 + (z³ - 3z)γ₂/24 - (2z³ - 5z)γ₁²/36]
    z2 = z * z
    z3 = z2 * z

    term1 = (z2 - 1) * γ₁ / 6              # skewness correction
    term2 = (z3 - 3 * z) * γ₂ / 24         # kurtosis correction
    term3 = -(2 * z3 - 5 * z) * γ₁^2 / 36  # skewness² correction

    w = z + term1 + term2 + term3
    quantile = μ + σ * w

    return MomentQuantileResult{T_float}(
        quantile,
        true,
        p_f,
        μ,
        σ²,
        γ₁,
        γ₂,
        "Cornish-Fisher expansion assuming near-Gaussian distribution; " *
        "accuracy depends on how close the true distribution is to normal",
    )
end

"""
    moment_quantile(p::Real, summary::ScalarSummary{T}) -> MomentQuantileResult{T}

Estimate a quantile from a `ScalarSummary` with higher moments.

Derives the population central moments from the raw power sums:
- mean = sum / count
- variance = sumsq / count - mean²
- skewness = (m3 / count - 3*mean*variance - mean³) / σ³
- excess_kurtosis = (m4 / count - 4*mean*(m3/count) + 6*mean²*var + 3*mean⁴) / σ⁴ - 3

Raises `DomainError` if:
- count is zero
- `higher_moment` is false (insufficient moments for Cornish-Fisher)

See REQ-30.
"""
function moment_quantile(p::Real, summary::ScalarSummary{T}) where {T}
    # Require higher moments (REQ-30: insufficient moments fails)
    summary.schema.higher_moment || throw(
        DomainError(
            summary.schema.higher_moment,
            "moment_quantile: ScalarSummary must have higher_moment=true " *
            "for Cornish-Fisher estimation (REQ-30)",
        ),
    )

    summary.count > 0 || throw(DomainError(summary.count, "moment_quantile: count is zero"))

    n = T(summary.count)

    # Raw moments (from power sums)
    μ = summary.sum / n                     # first raw moment (mean)

    # Central moments from raw power sums
    # E[(X-μ)²] = E[X²] - μ²
    # E[(X-μ)³] = E[X³] - 3μE[X²] + 2μ³
    # E[(X-μ)⁴] = E[X⁴] - 4μE[X³] + 6μ²E[X²] - 3μ⁴

    m2 = summary.sumsq / n - μ^2            # second central moment (variance)
    m3_raw = summary.m3 / n                 # third raw moment
    m3_central = m3_raw - 3 * μ * (summary.sumsq / n) + 2 * μ^3
    m4_raw = summary.m4 / n                 # fourth raw moment
    m4_central = m4_raw - 4 * μ * m3_raw + 6 * μ^2 * (summary.sumsq / n) - 3 * μ^4

    σ² = max(m2, zero(T))                   # clamp tiny negative rounding errors
    σ³ = σ² * sqrt(m2)

    # Standardized moments
    γ₁ = σ² > 0 ? m3_central / σ³ : zero(T)
    γ₂ = σ² > 0 ? m4_central / σ²^2 - 3 : zero(T)  # excess kurtosis

    return moment_quantile(p, μ, σ², γ₁, γ₂)
end

end # module SampleAnalytics
