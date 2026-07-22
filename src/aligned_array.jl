"""
    Tray.AlignedArray

Aligned array payload and derived statistics: elementwise-vector aggregates
with ordered-dimension identity validation, quadratic projection (REQ-16),
and normalized covariance contribution (REQ-17).

Exports:
- `AlignedArrayPayload` — a tree payload with a fixed-length aligned vector
- `quadratic_projection` — wᵀMw with dimension alignment (REQ-16)
- `normalized_covariance_contribution` — cov(N,A)/σ_A (REQ-17)
- `AlignedArrayError` — thrown on alignment or validation failures
"""
module AlignedArray

import ..TrayBase
import ..Tray: ScalarSchema, ScalarSummary, Tree
import LinearAlgebra: cholesky, dot, issymmetric, PosDefException

export AlignedArrayPayload,
    quadratic_projection, normalized_covariance_contribution, AlignedArrayError

# ---------------------------------------------------------------------------
# Exception types
# ---------------------------------------------------------------------------

"""
    AlignedArrayError

Thrown when AlignedArrayPayload operations encounter alignment or validation
failures: mismatched dimensions, non-finite values, etc.
"""
struct AlignedArrayError <: Exception
    message::String
end

Base.showerror(io::IO, e::AlignedArrayError) = print(io, "AlignedArrayError: ", e.message)

# ---------------------------------------------------------------------------
# AlignedArrayPayload
# ---------------------------------------------------------------------------

"""
    AlignedArrayPayload{T}

A tree payload containing a finite aligned vector of fixed length K with
immutable ordered unique dimension identifiers.

- `values::Vector{T}` — the vector values (length K, all finite)
- `dim_ids::Vector{String}` — ordered unique dimension identifiers
- `summary::ScalarSummary{T}` — scalar summary aggregated from the vector

Two AlignedArrayPayloads can only be combined when they have the same dimension
identifiers in the same order. Mismatches raise an AlignedArrayError (REQ-33).

Identity: zero vector, count=0 for summary.

See REQ-4, REQ-7, REQ-33, REQ-43.
"""
struct AlignedArrayPayload{T}
    values::Vector{T}
    dim_ids::Vector{String}
    summary::ScalarSummary{T}

    function AlignedArrayPayload{T}(
        values::Vector{T},
        dim_ids::Vector{String},
        summary::ScalarSummary{T},
    ) where {T}
        # Validate non-empty
        isempty(values) &&
            throw(AlignedArrayError("AlignedArrayPayload: values must be non-empty"))
        length(values) == length(dim_ids) || throw(
            AlignedArrayError(
                "AlignedArrayPayload: values length $(length(values)) must match dim_ids length $(length(dim_ids))",
            ),
        )

        # Validate all values are finite (except identity sentinel extrema)
        all(isfinite, values) ||
            throw(AlignedArrayError("AlignedArrayPayload: all values must be finite"))

        # Validate dimension identifiers are unique
        if length(Set(dim_ids)) != length(dim_ids)
            throw(
                AlignedArrayError(
                    "AlignedArrayPayload: dimension identifiers must be unique",
                ),
            )
        end

        return new{T}(values, dim_ids, summary)
    end
end

"""
    AlignedArrayPayload(values::Vector{T}, dim_ids::Vector{String}; schema = ScalarSchema{T}())

Construct an AlignedArrayPayload from values and dimension identifiers.
The scalar summary is computed automatically from the values.
"""
function AlignedArrayPayload(
    values::Vector{T},
    dim_ids::Vector{String};
    schema::ScalarSchema{T} = ScalarSchema{T}(),
) where {T}
    isempty(values) &&
        throw(AlignedArrayError("AlignedArrayPayload: values must be non-empty"))

    # Compute scalar summary from values
    n = length(values)
    s = sum(values)
    sq = sum(v * v for v in values)
    mn = minimum(values)
    mx = maximum(values)
    summary = ScalarSummary{T}(schema, n, s, sq, mn, mx)

    return AlignedArrayPayload{T}(values, dim_ids, summary)
end

"""
    identity(schema::ScalarSchema{T}, dim_ids::Vector{String}) -> AlignedArrayPayload{T}

Return the identity AlignedArrayPayload: all-zero vector with the given dimension
identifiers, schema's identity summary.
"""
function TrayBase.identity(schema::ScalarSchema{T}, dim_ids::Vector{String}) where {T}
    isempty(dim_ids) &&
        throw(AlignedArrayError("AlignedArrayPayload identity: dim_ids must be non-empty"))
    if length(Set(dim_ids)) != length(dim_ids)
        throw(
            AlignedArrayError(
                "AlignedArrayPayload identity: dimension identifiers must be unique",
            ),
        )
    end

    zero_values = zeros(T, length(dim_ids))
    id_summary = TrayBase.identity(schema)
    return AlignedArrayPayload{T}(zero_values, dim_ids, id_summary)
end

"""
    identity(schema::ScalarSchema{T}, ::Type{AlignedArrayPayload{T}}) -> AlignedArrayPayload{T}

Prototype-based identity — raises an error (use the `dim_ids`-aware overload instead).
"""
function TrayBase.identity(
    schema::ScalarSchema{T},
    ::Type{AlignedArrayPayload{T}},
) where {T}
    throw(
        AlignedArrayError(
            "AlignedArrayPayload identity requires dim_ids; use " *
            "identity(schema, dim_ids) instead of identity(schema, AlignedArrayPayload{T})",
        ),
    )
end

"""
    identity(schema::ScalarSchema{T}, ::Type{AlignedArrayPayload{T}}, prototype::AlignedArrayPayload{T}) -> AlignedArrayPayload{T}

Prototype-based identity: use the prototype's dimension identifiers.
"""
function TrayBase.identity(
    schema::ScalarSchema{T},
    ::Type{AlignedArrayPayload{T}},
    prototype::AlignedArrayPayload{T},
) where {T}
    return TrayBase.identity(schema, prototype.dim_ids)
end

"""
    combine(a::AlignedArrayPayload{T}, b::AlignedArrayPayload{T}) -> AlignedArrayPayload{T}

Elementwise vector addition. Both payloads must have identical dimension
identifiers in the same order (REQ-7, REQ-33).
"""
function TrayBase.combine(a::AlignedArrayPayload{T}, b::AlignedArrayPayload{T}) where {T}
    # Alignment check
    if a.dim_ids != b.dim_ids
        throw(
            AlignedArrayError(
                "AlignedArrayPayload: cannot combine payloads with different " *
                "dimension identifiers; left has $(length(a.dim_ids)) ids, " *
                "right has $(length(b.dim_ids)) ids",
            ),
        )
    end

    combined_values = a.values + b.values
    combined_summary = TrayBase.combine(a.summary, b.summary)
    return AlignedArrayPayload{T}(combined_values, a.dim_ids, combined_summary)
end

function TrayBase.combine(a::AlignedArrayPayload, b::AlignedArrayPayload)
    throw(
        AlignedArrayError(
            "AlignedArrayPayload type mismatch: cannot combine $(typeof(a)) with $(typeof(b))",
        ),
    )
end

"""
    reweight(payload::AlignedArrayPayload{T}, weight::Number) -> AlignedArrayPayload{T}

Scale all values by weight.
"""
function TrayBase.reweight(payload::AlignedArrayPayload{T}, weight::Number) where {T}
    w = convert(T, weight)
    new_values = payload.values .* w
    new_summary = TrayBase.reweight(payload.summary, w)
    return AlignedArrayPayload{T}(new_values, payload.dim_ids, new_summary)
end

# ---------------------------------------------------------------------------
# Equality and hashing
# ---------------------------------------------------------------------------

function Base.:(==)(a::AlignedArrayPayload{T}, b::AlignedArrayPayload{T}) where {T}
    return a.values == b.values && a.dim_ids == b.dim_ids && a.summary == b.summary
end

Base.:(==)(a::AlignedArrayPayload, b::AlignedArrayPayload) = false

function Base.hash(a::AlignedArrayPayload{T}, h::UInt) where {T}
    return hash(a.values, hash(a.dim_ids, hash(a.summary, h)))
end

# ---------------------------------------------------------------------------
# Show
# ---------------------------------------------------------------------------

function Base.show(io::IO, p::AlignedArrayPayload{T}) where {T}
    k = length(p.values)
    print(
        io,
        "AlignedArrayPayload{$T}($(k) dims, ",
        "count=$(p.summary.count), sum=$(p.summary.sum))",
    )
end

# ---------------------------------------------------------------------------
# REQ-16: Quadratic matrix projection
# ---------------------------------------------------------------------------

"""
    quadratic_projection(w::AlignedArrayPayload{T}, M::AbstractMatrix{T}) -> T

Compute `wᵀ M w` where `w` is an aligned vector and `M` is a symmetric
positive-semidefinite matrix whose dimensions are labeled and ordered
exactly as in `w`.

The matrix `M` is provided as a `K×K` matrix with dimension identifiers
passed separately via `dim_ids`.

    quadratic_projection(w::AlignedArrayPayload{T}, M::AbstractMatrix{T}, dim_ids::Vector{String}) -> T

Compute the quadratic projection when matrix dimension labels are provided.

See REQ-16.
"""
function quadratic_projection(
    w::AlignedArrayPayload{T},
    M::AbstractMatrix{T},
    dim_ids::Vector{String},
) where {T}
    n = length(w.values)
    n == size(M, 1) == size(M, 2) || throw(
        AlignedArrayError(
            "quadratic_projection: w has $n dimensions but M is $(size(M,1))×$(size(M,2))",
        ),
    )
    n == length(dim_ids) || throw(
        AlignedArrayError(
            "quadratic_projection: w has $n dimensions but dim_ids has length $(length(dim_ids))",
        ),
    )

    # Check dimension identifier alignment
    w.dim_ids == dim_ids || throw(
        AlignedArrayError(
            "quadratic_projection: w dimension identifiers do not match dim_ids",
        ),
    )

    # Validate matrix: finite, square, symmetric
    all(isfinite, M) || throw(
        AlignedArrayError("quadratic_projection: matrix M must have all finite entries"),
    )
    issymmetric(M) ||
        throw(AlignedArrayError("quadratic_projection: matrix M must be symmetric"))

    # Check positive-semidefinite via Cholesky (will throw PosDefException if not)
    # Use try-catch for non-PSD detection
    try
        cholesky(M)
    catch e
        if isa(e, PosDefException)
            throw(
                AlignedArrayError(
                    "quadratic_projection: matrix M must be positive-semidefinite",
                ),
            )
        else
            rethrow(e)
        end
    end

    # Compute wᵀ M w
    Mw = M * w.values
    return dot(w.values, Mw)
end

"""
    quadratic_projection(w::AlignedArrayPayload{T}, M::AbstractMatrix{T}) -> T

Convenience overload: derive dim_ids from `w` when `M` has the same dimensions.
"""
function quadratic_projection(w::AlignedArrayPayload{T}, M::AbstractMatrix{T}) where {T}
    return quadratic_projection(w, M, w.dim_ids)
end

# ---------------------------------------------------------------------------
# REQ-17: Normalized covariance contribution
# ---------------------------------------------------------------------------

"""
    normalized_covariance_contribution(N::AlignedArrayPayload{T}, A::AlignedArrayPayload{T}) -> T

Compute the normalized covariance contribution `cov(N, A) / σ_A` between
aligned node and ancestor samples.

Returns the population covariance divided by the ancestor population standard
deviation. Throws AlignedArrayError if:
- Samples are misaligned (different dimensions or identifiers)
- Ancestor variance is zero (σ_A = 0)

See REQ-17.
"""
function normalized_covariance_contribution(
    N::AlignedArrayPayload{T},
    A::AlignedArrayPayload{T},
) where {T}
    # Alignment check
    if N.dim_ids != A.dim_ids
        throw(
            AlignedArrayError(
                "normalized_covariance_contribution: node and ancestor " *
                "have different dimension identifiers",
            ),
        )
    end

    n_n = N.summary.count
    n_a = A.summary.count

    n_n > 0 || throw(
        AlignedArrayError(
            "normalized_covariance_contribution: node sample count must be positive",
        ),
    )
    n_a > 0 || throw(
        AlignedArrayError(
            "normalized_covariance_contribution: ancestor sample count must be positive",
        ),
    )

    # Population covariance: cov(N, A) = E[NA] - E[N]E[A]
    # where E[NA] = (1/n) Σ N_i * A_i, E[N] = mean(N), E[A] = mean(A)
    #
    # For aligned vectors, E[NA] = sum(N.values .* A.values) / n
    # where n = n_n (but if counts differ, use min or report alignment issue)

    # Since these are aligned, we use the first n elements of each where n = min(n_n, n_a)
    # Actually for AlignedArrayPayload, count is the number of observations that produced
    # the summary. The values are the aligned array elements.
    # For covariance between two aligned arrays of the same dimension K:
    # cov(N, A) = (1/K) * Σ_i (N_i - mean(N)) * (A_i - mean(A))
    #            = (1/K) * Σ_i N_i * A_i - mean(N) * mean(A)

    k = length(N.values)
    k == length(A.values) || throw(
        AlignedArrayError(
            "normalized_covariance_contribution: node and ancestor vector lengths differ",
        ),
    )

    mean_N = N.summary.sum / n_n
    mean_A = A.summary.sum / n_a

    # E[NA] = sum of elementwise products / k
    e_na = dot(N.values, A.values) / k

    cov_na = e_na - mean_N * mean_A

    # Ancestor population variance
    var_A = A.summary.sumsq / n_a - mean_A^2
    var_A > 0 || throw(
        AlignedArrayError(
            "normalized_covariance_contribution: ancestor variance must be positive, " *
            "got $var_A",
        ),
    )

    σ_A = sqrt(var_A)
    return cov_na / σ_A
end

end # module AlignedArray
