"""
    ScalarSchema{T}

Schema bound to a tree capturing numeric type and whether higher moments (m3, m4)
are stored. Identity is bound to this schema.
"""
struct ScalarSchema{T}
    higher_moment::Bool

    ScalarSchema{T}(higher_moment::Bool = false) where {T} = new{T}(higher_moment)
end

Base.eltype(::Type{ScalarSchema{T}}) where {T} = T

"""
    ScalarSummary

Built-in convenience payload containing `count`, `sum`, `sumsq`, `minimum`, and
`maximum`. Optionally stores third- and fourth-power sums (`m3`, `m4`) when the
schema has `higher_moment=true`.

Identity (count=0): `sum=sumsq=0`, `minimum=+Inf`, `maximum=-Inf`, optional
higher sums zero. These sentinel extrema are the only permitted non-finite
stored values. A nonzero count must have finite consistent sums and extrema.

See REQ-4.
"""
struct ScalarSummary{T}
    schema::ScalarSchema{T}
    count::Int
    sum::T
    sumsq::T
    minimum::T
    maximum::T
    m3::T  # sum of cubed deviations (0 when higher_moment=false)
    m4::T  # sum of fourth powers of deviations (0 when higher_moment=false)

    function ScalarSummary{T}(
        schema::ScalarSchema{T},
        count::Int,
        sum::T,
        sumsq::T,
        minimum::T,
        maximum::T,
        m3::T = zero(T),
        m4::T = zero(T),
    ) where {T}
        # Validate count non-negative
        count >= 0 || throw(ArgumentError("ScalarSummary: count must be ≥ 0, got $count"))

        # Validate higher-moment schema consistency
        if !schema.higher_moment && (m3 != zero(T) || m4 != zero(T))
            throw(
                ArgumentError(
                    "ScalarSummary: higher_moment=false but m3=$m3, m4=$m4; set higher_moment=true or pass zero",
                ),
            )
        end

        if count == 0
            # Identity: canonical sentinel values
            sum == zero(T) ||
                throw(ArgumentError("ScalarSummary identity: sum must be 0, got $sum"))
            sumsq == zero(T) ||
                throw(ArgumentError("ScalarSummary identity: sumsq must be 0, got $sumsq"))
            isinf(minimum) && minimum == +T(Inf) || throw(
                ArgumentError("ScalarSummary identity: minimum must be +Inf, got $minimum"),
            )
            isinf(maximum) && maximum == -T(Inf) || throw(
                ArgumentError("ScalarSummary identity: maximum must be -Inf, got $maximum"),
            )
            m3 == zero(T) ||
                throw(ArgumentError("ScalarSummary identity: m3 must be 0, got $m3"))
            m4 == zero(T) ||
                throw(ArgumentError("ScalarSummary identity: m4 must be 0, got $m4"))
        else
            # Non-zero count: all values must be finite
            isfinite(sum) || throw(
                ArgumentError(
                    "ScalarSummary: non-identity payload must have finite sum, got $sum",
                ),
            )
            isfinite(sumsq) || throw(
                ArgumentError(
                    "ScalarSummary: non-identity payload must have finite sumsq, got $sumsq",
                ),
            )
            isfinite(minimum) || throw(
                ArgumentError(
                    "ScalarSummary: non-identity payload must have finite minimum, got $minimum",
                ),
            )
            isfinite(maximum) || throw(
                ArgumentError(
                    "ScalarSummary: non-identity payload must have finite maximum, got $maximum",
                ),
            )
            isfinite(m3) || throw(
                ArgumentError(
                    "ScalarSummary: non-identity payload must have finite m3, got $m3",
                ),
            )
            isfinite(m4) || throw(
                ArgumentError(
                    "ScalarSummary: non-identity payload must have finite m4, got $m4",
                ),
            )

            # Check consistent extrema
            minimum <= maximum || throw(
                ArgumentError(
                    "ScalarSummary: minimum ($minimum) must be ≤ maximum ($maximum)",
                ),
            )
        end

        return new{T}(schema, count, sum, sumsq, minimum, maximum, m3, m4)
    end
end

"""
    ScalarSummary(; schema, count, sum, sumsq, minimum, maximum, [m3, m4])

Convenience keyword constructor. Delegates to the positional inner constructor.
`m3` and `m4` default to `zero(T)` when omitted.
"""
function ScalarSummary(;
    schema,
    count,
    sum,
    sumsq,
    minimum,
    maximum,
    m3 = nothing,
    m4 = nothing,
)
    T = eltype(schema)
    _m3 = something(m3, zero(T))
    _m4 = something(m4, zero(T))
    return ScalarSummary{T}(schema, count, sum, sumsq, minimum, maximum, _m3, _m4)
end

"""
    identity(schema::ScalarSchema) -> ScalarSummary

Return the unique identity `ScalarSummary` for the given schema.
"""
function TrayBase.identity(schema::ScalarSchema{T}) where {T}
    inf_pos = T(Inf)
    inf_neg = T(-Inf)
    return ScalarSummary{T}(schema, 0, zero(T), zero(T), inf_pos, inf_neg, zero(T), zero(T))
end

"""
    combine(a::ScalarSummary{T}, b::ScalarSummary{T}) -> ScalarSummary{T}

Component-wise aggregation: sum/sumsq/m3/m4 add, count adds, minimum takes the
lesser, maximum takes the greater. Raises `ArgumentError` if schemas differ.
"""
function TrayBase.combine(a::ScalarSummary{T}, b::ScalarSummary{T}) where {T}
    # Schema must match
    a.schema == b.schema ||
        throw(ArgumentError("schema mismatch: $(a.schema) vs $(b.schema)"))

    return ScalarSummary{T}(
        a.schema,
        a.count + b.count,
        a.sum + b.sum,
        a.sumsq + b.sumsq,
        min(a.minimum, b.minimum),
        max(a.maximum, b.maximum),
        a.m3 + b.m3,
        a.m4 + b.m4,
    )
end

"""
    ==(a::ScalarSchema, b::ScalarSchema) -> Bool

Structural equality of schema type and parameters.
"""
function Base.:(==)(a::ScalarSchema{T}, b::ScalarSchema{T}) where {T}
    return a.higher_moment == b.higher_moment
end
Base.:(==)(a::ScalarSchema, b::ScalarSchema) = false

"""
    hash(a::ScalarSchema, h::UInt) -> UInt

"""
function Base.hash(a::ScalarSchema, h::UInt)
    return hash(a.higher_moment, hash(T, h))
end

"""
    ==(a::ScalarSummary, b::ScalarSummary) -> Bool

Structural equality including schema.
"""
function Base.:(==)(a::ScalarSummary{T}, b::ScalarSummary{T}) where {T}
    return a.schema == b.schema &&
           a.count == b.count &&
           a.sum == b.sum &&
           a.sumsq == b.sumsq &&
           a.minimum == b.minimum &&
           a.maximum == b.maximum &&
           a.m3 == b.m3 &&
           a.m4 == b.m4
end
Base.:(==)(a::ScalarSummary, b::ScalarSummary) = false

"""
    hash(a::ScalarSummary, h::UInt) -> UInt

Hash based on structural fields including schema.
"""
function Base.hash(a::ScalarSummary, h::UInt)
    return hash(
        a.schema,
        hash(
            a.count,
            hash(
                a.sum,
                hash(a.sumsq, hash(a.minimum, hash(a.maximum, hash(a.m3, hash(a.m4, h))))),
            ),
        ),
    )
end

"""
    show(io::IO, s::ScalarSummary)

Compact REPL display.
"""
function Base.show(io::IO, s::ScalarSummary{T}) where {T}
    if s.schema.higher_moment
        print(
            io,
            "ScalarSummary{$T}(",
            s.count,
            " entries, sum=",
            s.sum,
            ", sumsq=",
            s.sumsq,
            ", min=",
            s.minimum,
            ", max=",
            s.maximum,
            ", m3=",
            s.m3,
            ", m4=",
            s.m4,
            ")",
        )
    else
        print(
            io,
            "ScalarSummary{$T}(",
            s.count,
            " entries, sum=",
            s.sum,
            ", sumsq=",
            s.sumsq,
            ", min=",
            s.minimum,
            ", max=",
            s.maximum,
            ")",
        )
    end
end

"""
    TrayBase.reweight(s::ScalarSummary{T}, weight::Number) -> ScalarSummary{T}

Scale `sum` and `sumsq` by `weight`. Count, minimum, and maximum are
preserved unchanged (weight affects only aggregate-dependent fields).

Weight must be ≥ 0. Weight 1.0 is the identity.

See REQ-18, REQ-29.
"""
function TrayBase.reweight(s::ScalarSummary{T}, weight::Number) where {T}
    weight >= 0 || throw(ArgumentError("reweight: weight must be ≥ 0, got $weight"))
    return ScalarSummary{T}(
        s.schema,
        s.count,
        s.sum * weight,
        s.sumsq * weight,
        s.minimum,
        s.maximum,
        s.m3,
        s.m4,
    )
end
