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

end # module TrayBase
