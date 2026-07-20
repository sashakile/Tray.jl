"""
    AttributionConvention

Abstract type for attribution convention configuration. See REQ-47.
"""
abstract type AttributionConvention end

"""
    Direct <: AttributionConvention

Convention for externally supplied attribution buckets where no cross-term
allocation method is needed. The library only aggregates the supplied buckets.
"""
struct Direct <: AttributionConvention end

"""
    Allocated <: AttributionConvention

Convention for buckets derived from simultaneously changing factors.
Records the allocation method and ordered factor IDs.

Supported methods:
- `:sequential` — sequential allocation with declared factor order
- `:symmetric` — symmetric (e.g., Shapley-based) allocation
"""
struct Allocated <: AttributionConvention
    method::Symbol
    ordered_factor_ids::Vector{Symbol}

    function Allocated(method::Symbol, ordered_factor_ids::Vector{Symbol})
        method in (:sequential, :symmetric) || throw(
            ArgumentError(
                "unsupported allocation method: $method; expected :sequential or :symmetric",
            ),
        )
        length(ordered_factor_ids) >= 1 ||
            throw(ArgumentError("Allocated: must have at least one factor ID"))
        return new(method, ordered_factor_ids)
    end
end

Base.:(==)(a::Allocated, b::Allocated) =
    a.method == b.method && a.ordered_factor_ids == b.ordered_factor_ids

function Base.hash(a::Allocated, h::UInt)
    return hash(a.ordered_factor_ids, hash(a.method, h))
end

Base.show(io::IO, ::Direct) = print(io, "Direct()")

function Base.show(io::IO, a::Allocated)
    print(io, "Allocated(:$(a.method), $(a.ordered_factor_ids))")
end

"""
    AttributionSchema{K, T}

Schema for `AttributionPayload{K}`. Records:
- `bucket_ids` — ordered unique bucket identifiers (type-stable tuple, length `K`)
- `tolerance` — numerical tolerance for bucket-sum reconciliation (REQ-46)
- `residual_bucket_id` — optional bucket ID for absorbing residual gaps (`nothing` to reject)
- `convention` — `Direct` or `Allocated` attribution convention (REQ-47)
"""
struct AttributionSchema{K,T}
    bucket_ids::NTuple{K,Symbol}
    tolerance::T
    residual_bucket_id::Union{Nothing,Symbol}
    convention::AttributionConvention

    function AttributionSchema{K,T}(
        bucket_ids::NTuple{K,Symbol},
        tolerance::T,
        residual_bucket_id::Union{Nothing,Symbol},
        convention::AttributionConvention,
    ) where {K,T}
        # K must be positive (REQ-45: positive length)
        K > 0 || throw(ArgumentError("AttributionSchema: K must be positive, got $K"))

        # Validate unique bucket IDs
        length(unique(bucket_ids)) == K || throw(
            ArgumentError("AttributionSchema: bucket_ids must be unique, got $bucket_ids"),
        )

        # Validate tolerance is positive finite
        tolerance > zero(T) && isfinite(tolerance) || throw(
            ArgumentError(
                "AttributionSchema: tolerance must be positive finite, got $tolerance",
            ),
        )

        # Validate residual_bucket_id is in bucket_ids when present
        if residual_bucket_id !== nothing
            residual_bucket_id in bucket_ids || throw(
                ArgumentError(
                    "AttributionSchema: residual_bucket_id=$residual_bucket_id not found in bucket_ids $bucket_ids",
                ),
            )
        end

        return new{K,T}(bucket_ids, tolerance, residual_bucket_id, convention)
    end
end

"""
    AttributionSchema(; bucket_ids, tolerance, residual_bucket_id, convention)

Convenience keyword constructor. Infers `K` and `T` from the arguments.
"""
function AttributionSchema(;
    bucket_ids::NTuple{K,Symbol},
    tolerance::T,
    residual_bucket_id::Union{Nothing,Symbol},
    convention::AttributionConvention,
) where {K,T}
    return AttributionSchema{K,T}(bucket_ids, tolerance, residual_bucket_id, convention)
end

Base.eltype(::Type{AttributionSchema{K,T}}) where {K,T} = T

"""
    ==(a::AttributionSchema{K, T}, b::AttributionSchema{K, T}) -> Bool

Structural equality with same type parameters.
"""
function Base.:(==)(a::AttributionSchema{K,T}, b::AttributionSchema{K,T}) where {K,T}
    return a.bucket_ids == b.bucket_ids &&
           a.tolerance == b.tolerance &&
           a.residual_bucket_id == b.residual_bucket_id &&
           a.convention == b.convention
end
Base.:(==)(a::AttributionSchema, b::AttributionSchema) = false

"""
    hash(a::AttributionSchema, h::UInt) -> UInt
"""
function Base.hash(a::AttributionSchema{K,T}, h::UInt) where {K,T}
    return hash(
        a.convention,
        hash(
            a.residual_bucket_id,
            hash(a.tolerance, hash(a.bucket_ids, hash(K, hash(T, h)))),
        ),
    )
end

"""
    AttributionPayload{K, T}

Bucketed additive attribution payload containing:
- `schema` — associated `AttributionSchema{K, T}`
- `buckets` — finite vector of length `K` (ordered matching schema's `bucket_ids`)
- `realized_total` — finite total that `sum(buckets)` must reconcile with

See REQ-45, REQ-46.
"""
struct AttributionPayload{K,T}
    schema::AttributionSchema{K,T}
    buckets::Vector{T}
    realized_total::T

    function AttributionPayload{K,T}(
        schema::AttributionSchema{K,T},
        buckets::Vector{T},
        realized_total::T,
    ) where {K,T}
        # Validate bucket count
        length(buckets) == K || throw(
            ArgumentError(
                "AttributionPayload: expected $K buckets, got $(length(buckets))",
            ),
        )

        # Validate finite values
        all(isfinite, buckets) ||
            throw(ArgumentError("AttributionPayload: all buckets must be finite"))
        isfinite(realized_total) || throw(
            ArgumentError(
                "AttributionPayload: realized_total must be finite, got $realized_total",
            ),
        )

        # Bucket-sum reconciliation (REQ-46)
        bucket_sum = sum(buckets)
        gap = realized_total - bucket_sum
        if abs(gap) > schema.tolerance
            if schema.residual_bucket_id !== nothing
                # Find residual bucket index and assign the gap
                residual_idx = findfirst(==(schema.residual_bucket_id), schema.bucket_ids)
                buckets = copy(buckets)
                buckets[residual_idx] += gap
            else
                throw(
                    ArgumentError(
                        "AttributionPayload: bucket_sum=$bucket_sum does not reconcile " *
                        "with realized_total=$realized_total (gap=$gap, tolerance=$(schema.tolerance)); " *
                        "no residual bucket designated",
                    ),
                )
            end
        end

        return new{K,T}(schema, buckets, realized_total)
    end
end

"""
    AttributionPayload(; schema, buckets, realized_total)

Convenience keyword constructor. Infers `K` and `T` from the schema.
"""
function AttributionPayload(;
    schema::AttributionSchema{K,T},
    buckets::Vector{T},
    realized_total::T,
) where {K,T}
    return AttributionPayload{K,T}(schema, buckets, realized_total)
end

"""
    identity(schema::AttributionSchema{K, T}) -> AttributionPayload{K, T}

Return the unique identity `AttributionPayload` for the given schema:
zero buckets, zero realized_total.
"""
function TrayBase.identity(schema::AttributionSchema{K,T}) where {K,T}
    return AttributionPayload{K,T}(schema, zeros(T, K), zero(T))
end

"""
    combine(a::AttributionPayload{K, T}, b::AttributionPayload{K, T}) -> AttributionPayload{K, T}

Elementwise bucket addition and realized-total addition.
Schemas must match structurally (same bucket IDs, tolerance, residual, convention).
Raises `ArgumentError` on schema mismatch or misaligned bucket IDs.
"""
function TrayBase.combine(
    a::AttributionPayload{K,T},
    b::AttributionPayload{K,T},
) where {K,T}
    # Schema must match structurally
    a.schema == b.schema || throw(
        ArgumentError("AttributionPayload schema mismatch: $(a.schema) vs $(b.schema)"),
    )

    return AttributionPayload{K,T}(
        a.schema,
        a.buckets .+ b.buckets,
        a.realized_total + b.realized_total,
    )
end

# Fallback for mismatched types (different K, different T, or non-AttributionPayload)
function TrayBase.combine(a::AttributionPayload, b::AttributionPayload)
    throw(
        ArgumentError(
            "AttributionPayload alignment error: cannot combine type $(typeof(a)) with $(typeof(b))",
        ),
    )
end

"""
    ==(a::AttributionPayload{K, T}, b::AttributionPayload{K, T}) -> Bool

Structural equality including schema.
"""
function Base.:(==)(a::AttributionPayload{K,T}, b::AttributionPayload{K,T}) where {K,T}
    return a.schema == b.schema &&
           a.buckets == b.buckets &&
           a.realized_total == b.realized_total
end
Base.:(==)(a::AttributionPayload, b::AttributionPayload) = false

"""
    hash(a::AttributionPayload, h::UInt) -> UInt
"""
function Base.hash(a::AttributionPayload{K,T}, h::UInt) where {K,T}
    return hash(a.schema, hash(a.realized_total, hash(a.buckets, h)))
end

"""
    show(io::IO, p::AttributionPayload)

Compact REPL display.
"""
function Base.show(io::IO, p::AttributionPayload{K,T}) where {K,T}
    print(io, "AttributionPayload{$K, $T}(")
    join(io, ["$(id)=$(val)" for (id, val) in zip(p.schema.bucket_ids, p.buckets)], ", ")
    print(io, "; realized_total=", p.realized_total, ")")
end

"""
    derive_ratio(payload::AttributionPayload, numerator_id::Symbol, denominator_id::Symbol)

Derive a ratio from two bucket fields at read time. Never stored or combined.
Returns `numerator / denominator` from the payload's bucket values.
Throws `DomainError` when denominator is zero.
Throws `ArgumentError` when either bucket ID is not found in the schema.

See REQ-48.
"""
function derive_ratio(
    payload::AttributionPayload{K,T},
    numerator_id::Symbol,
    denominator_id::Symbol,
) where {K,T}
    num_idx = findfirst(==(numerator_id), payload.schema.bucket_ids)
    num_idx !== nothing || throw(
        ArgumentError(
            "derive_ratio: numerator_id=:$numerator_id not found in schema bucket_ids",
        ),
    )

    den_idx = findfirst(==(denominator_id), payload.schema.bucket_ids)
    den_idx !== nothing || throw(
        ArgumentError(
            "derive_ratio: denominator_id=:$denominator_id not found in schema bucket_ids",
        ),
    )

    denominator = payload.buckets[den_idx]
    denominator == zero(T) &&
        throw(DomainError(denominator, "derive_ratio: denominator is zero"))

    return payload.buckets[num_idx] / denominator
end

"""
    derive_ratio(payload::AttributionPayload, numerator_id::Symbol, denominator_id::Symbol, default::T)

Derive a ratio, returning `default` when denominator is zero.
"""
function derive_ratio(
    payload::AttributionPayload{K,T},
    numerator_id::Symbol,
    denominator_id::Symbol,
    default::T,
) where {K,T}
    den_idx = findfirst(==(denominator_id), payload.schema.bucket_ids)
    den_idx !== nothing || throw(
        ArgumentError(
            "derive_ratio: denominator_id=:$denominator_id not found in schema bucket_ids",
        ),
    )
    iszero(payload.buckets[den_idx]) && return default
    return derive_ratio(payload, numerator_id, denominator_id)
end
