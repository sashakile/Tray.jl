"""
    TrayBase

Generic payload algebra interface: `combine(::T, ::T) -> T` and `identity(schema) -> T`.
Every payload type used in a tree must provide these methods.

# Extending for custom payloads
To use a custom payload type `MyPayload` with Tray:
1. Define `TrayBase.combine(a::MyPayload, b::MyPayload)::MyPayload`
2. Define `TrayBase.identity(schema::MySchema)::MyPayload` satisfying the identity laws
"""
module TrayBase

"""
    combine(a, b)

Aggregate two payload values. Must be closed over type `T` (return `T`).
"""
function combine(a, b)
    error("combine not implemented for $(typeof(a)) and $(typeof(b))")
end

"""
    identity(schema)

Return the unique identity payload for the given schema, satisfying both
`combine(identity(schema), x) == x` and `combine(x, identity(schema)) == x`.
"""
function identity(schema)
    error("identity not implemented for schema type $(typeof(schema))")
end

"""
    identity(schema, ::Type{P}, prototype)

Return the identity for the given schema and payload type, using `prototype`
as a template for parameters (e.g., sample length). By default, delegates
`identity(schema)`. Payload types with additional parameters override this
method to produce a correctly-sized identity.
"""
function identity(schema, ::Type{P}, prototype) where {P}
    return identity(schema)
end

"""
    reweight(payload, weight)

Return a new payload with values scaled by `weight`. Must be closed over the
payload type. Used by subtree reweighting (REQ-18) and lazy range updates (REQ-29).

Weight `1.0` SHALL be the identity: `reweight(x, 1.0) == x`.
"""
function reweight(payload, weight)
    error(
        "reweight not implemented for $(typeof(payload)). " *
        "Define `TrayBase.reweight(::$(typeof(payload)), ::typeof(weight))` " *
        "to enable subtree reweighting.",
    )
end

end # module TrayBase
