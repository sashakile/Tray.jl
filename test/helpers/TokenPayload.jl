# ── TokenPayload — test-only noncommutative payload (TRAYS-nyc.2, nyc.4) ─────
#
# A simple position-distinct payload: each leaf carries a unique integer token.
# combine concatenates tokens in order (noncommutative), so the root's token
# sequence equals the original leaf token vector — an independent oracle.
#
# This module is loaded only in the test environment.

module TestTokenPayload

using Tray: TrayBase

export TokenSchema, TokenPayload

struct TokenSchema end

struct TokenPayload{T}
    tokens::Vector{T}
end

Base.:(==)(a::TokenPayload, b::TokenPayload) = a.tokens == b.tokens
Base.hash(a::TokenPayload, h::UInt) = hash(a.tokens, h)

function TrayBase.identity(::TokenSchema)
    return TokenPayload{Int}(Int[])
end

function TrayBase.combine(a::TokenPayload{Int}, b::TokenPayload{Int})
    return TokenPayload{Int}(vcat(a.tokens, b.tokens))
end

function TrayBase.identity(
    ::TokenSchema,
    ::Type{TokenPayload{Int}},
    prototype::TokenPayload{Int},
)
    return TrayBase.identity(TokenSchema())
end

end
