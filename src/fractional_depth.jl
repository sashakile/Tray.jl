"""
    Tray.FractionalDepth

Fractional-depth queries: interpolate between adjacent ancestor levels
for general payloads (REQ-19) and sample quantiles (REQ-38).

Exports:
- `fractional_depth_query` — interpolate between ancestor projections (REQ-19)
- `fractional_depth_quantile` — interpolate sample quantiles (REQ-38)
- `FractionalDepthError` — raised on invalid fractional-depth requests
"""
module FractionalDepth

import ..TrayBase
import ..Tray: Tree, ScalarSummary, ScalarSchema, depth, leaf_count, root
import ..SampleAnalytics:
    SamplePayload,
    CompressedSamplePayload,
    exact_quantile,
    sketch_quantile,
    ApproximateResult

export fractional_depth_query,
    fractional_depth_quantile, FractionalDepthError, AffineProjection, projection_contract

# ---------------------------------------------------------------------------
# Exception
# ---------------------------------------------------------------------------

struct FractionalDepthError <: Exception
    message::String
end

Base.showerror(io::IO, e::FractionalDepthError) =
    print(io, "FractionalDepthError: ", e.message)

# ---------------------------------------------------------------------------
# Helper: find ancestor of a leaf at a given level
# ---------------------------------------------------------------------------

"""
    _ancestor_at_level(tree, leaf_idx, lvl) -> payload

Return the ancestor payload of leaf `leaf_idx` at tree level `lvl`.
Level 1 = leaves, level `max_level` = root.
Uses bottom-up parent index computation: parent = ceil(child / b).
"""
function _ancestor_at_level(tree::Tree, leaf_idx::Int, lvl::Int)
    b = tree.b
    idx = leaf_idx
    for _ = 2:lvl
        idx = cld(idx, b)  # ceil(idx / b)
    end
    return tree.levels[lvl][idx]
end

# ---------------------------------------------------------------------------
# Affine projection contract (REQ-19)
# ---------------------------------------------------------------------------

"""
    AffineProjection{ProjF, InterpF, S}

A declared affine projection contract for payload interpolation (REQ-19).

- `project(payload) -> A` — project a payload into affine space `A`
- `interpret(value, schema) -> payload` — convert an interpolated value back
- `space_id` — a unique identifier for the affine space (used for validation)

AffineProjection is used by `fractional_depth_query` to safely interpolate
between ancestor payloads at non-integer depths.
"""
struct AffineProjection{ProjF,InterpF,S}
    project::ProjF
    interpret::InterpF
    space_id::S
end

"""
    projection_contract(::Type{P}) -> Union{AffineProjection, Nothing}

Return the default affine projection contract for payload type `P`, or
`nothing` if the payload does not declare one. Payload authors implement
this method to opt into projection-based interpolation.

See REQ-19.
"""
function projection_contract(::Type{P}) where {P}
    return nothing
end

# ---------------------------------------------------------------------------
# REQ-19: Fractional-depth query (general payloads)
# ---------------------------------------------------------------------------

"""
    fractional_depth_query(tree, focus_leaf::Int, d::Real;
                           projection = nothing) -> Any

Resolve a fractional-depth query for focus leaf `focus_leaf` at depth `d`
in `[0, max_depth]`.

- `d = 0` → root, `d = max_depth` → leaf level
- Integer `d` returns the exact ancestor payload without projection (REQ-19).
- Non-integer `d` requires an explicit `projection` (an `AffineProjection` or
  compatible callable with `project` and `interpret`). Both adjacent ancestors
  are projected, linearly interpolated in the affine space, and the result is
  interpreted back.

Throws `FractionalDepthError` on invalid inputs or when no projection is
provided for a non-integer query.

See REQ-19.
"""
function fractional_depth_query(
    tree::Tree{P},
    focus_leaf::Int,
    d::Real;
    projection = nothing,
) where {P}
    n = leaf_count(tree)
    1 <= focus_leaf <= n ||
        throw(FractionalDepthError("focus_leaf $focus_leaf out of bounds [1, $n]"))

    max_depth = depth(tree)
    0 <= d <= max_depth ||
        throw(FractionalDepthError("depth $d out of bounds [0, $max_depth]"))

    # Map depth d to tree level
    # depth 0 = root = level max_level, depth k = level max_level - k
    # where max_level = length(tree.levels)
    max_level = length(tree.levels)

    if d == floor(d)
        # Integer depth: return ancestor at that level (exact, no projection)
        lvl = max_level - Int(d)
        lvl >= 1 || throw(FractionalDepthError("internal: invalid level $lvl for depth $d"))
        return _ancestor_at_level(tree, focus_leaf, lvl)
    end

    # Non-integer depth: require a projection contract
    if projection === nothing
        throw(
            FractionalDepthError(
                "non-integer fractional_depth_query at depth $d requires a " *
                "projection contract (AffineProjection); pass `projection=...` " *
                "or declare a `projection_contract` for payload type $P",
            ),
        )
    end

    floor_d = Int(floor(d))
    ceil_d = Int(ceil(d))
    t = Float64(d - floor_d)  # fractional part, 0 < t < 1

    lvl_floor = max_level - floor_d
    lvl_ceil = max_level - ceil_d

    ancestor_floor = _ancestor_at_level(tree, focus_leaf, lvl_floor)
    ancestor_ceil = _ancestor_at_level(tree, focus_leaf, lvl_ceil)

    # Project both ancestors
    proj_floor = projection.project(ancestor_floor)
    proj_ceil = projection.project(ancestor_ceil)

    # Validate both projections belong to the same declared affine space
    space_id = projection.space_id
    # If space_id is a type, check isinstance; otherwise compare equality
    if space_id isa Type
        isa(proj_floor, space_id) && isa(proj_ceil, space_id) || throw(
            FractionalDepthError(
                "projection contract space_id=$space_id does not match " *
                "projected types $(typeof(proj_floor)) and $(typeof(proj_ceil))",
            ),
        )
    end

    # Linear interpolation: (1 - t) * floor + t * ceil
    interpolated = proj_floor * (1 - t) + proj_ceil * t

    # Apply result interpretation
    schema = tree.schema
    return projection.interpret(interpolated, schema)
end

# ---------------------------------------------------------------------------
# REQ-38: Fractional-depth sample quantile
# ---------------------------------------------------------------------------

"""
    fractional_depth_quantile(tree::Tree, focus_leaf::Int, d::Real,
                              p::Real) -> Union{Real, ApproximateResult}

Compute a sample quantile at fractional depth for a SamplePayload or
CompressedSamplePayload tree.

For exact SamplePayload trees, uses `exact_quantile` at each ancestor level
and interpolates the quantile values. For CompressedSamplePayload trees, uses
`sketch_quantile` and composes REQ-22 provenance conservatively.

The result is marked as approximate (non-integer depth always implies
interpolation uncertainty).

See REQ-38.
"""
function fractional_depth_quantile(
    tree::Tree{P},
    focus_leaf::Int,
    d::Real,
    p::Real,
) where {P<:SamplePayload}
    n = leaf_count(tree)
    1 <= focus_leaf <= n ||
        throw(FractionalDepthError("focus_leaf $focus_leaf out of bounds [1, $n]"))

    max_depth = depth(tree)
    0 <= d <= max_depth ||
        throw(FractionalDepthError("depth $d out of bounds [0, $max_depth]"))

    0 <= p <= 1 || throw(FractionalDepthError("probability p must be in [0, 1], got $p"))

    max_level = length(tree.levels)

    if d == floor(d)
        lvl = max_level - Int(d)
        ancestor = _ancestor_at_level(tree, focus_leaf, lvl)
        return exact_quantile(ancestor, p)
    end

    floor_d = Int(floor(d))
    ceil_d = Int(ceil(d))
    t = Float64(d - floor_d)

    lvl_floor = max_level - floor_d
    lvl_ceil = max_level - ceil_d

    ancestor_floor = _ancestor_at_level(tree, focus_leaf, lvl_floor)
    ancestor_ceil = _ancestor_at_level(tree, focus_leaf, lvl_ceil)

    q_floor = exact_quantile(ancestor_floor, p)
    q_ceil = exact_quantile(ancestor_ceil, p)

    return q_floor * (1 - t) + q_ceil * t
end

function fractional_depth_quantile(
    tree::Tree{P},
    focus_leaf::Int,
    d::Real,
    p::Real,
) where {P<:CompressedSamplePayload}
    n = leaf_count(tree)
    1 <= focus_leaf <= n ||
        throw(FractionalDepthError("focus_leaf $focus_leaf out of bounds [1, $n]"))

    max_depth = depth(tree)
    0 <= d <= max_depth ||
        throw(FractionalDepthError("depth $d out of bounds [0, $max_depth]"))

    0 <= p <= 1 || throw(FractionalDepthError("probability p must be in [0, 1], got $p"))

    max_level = length(tree.levels)

    if d == floor(d)
        lvl = max_level - Int(d)
        ancestor = _ancestor_at_level(tree, focus_leaf, lvl)
        return sketch_quantile(ancestor, p)
    end

    floor_d = Int(floor(d))
    ceil_d = Int(ceil(d))
    t = Float64(d - floor_d)

    lvl_floor = max_level - floor_d
    lvl_ceil = max_level - ceil_d

    ancestor_floor = _ancestor_at_level(tree, focus_leaf, lvl_floor)
    ancestor_ceil = _ancestor_at_level(tree, focus_leaf, lvl_ceil)

    r_floor = sketch_quantile(ancestor_floor, p)
    r_ceil = sketch_quantile(ancestor_ceil, p)

    interpolated_value = r_floor.value * (1 - t) + r_ceil.value * t

    # Conservatively compose rank-error bounds (REQ-22 / REQ-38)
    composed_error = max(r_floor.rank_error_bound, r_ceil.rank_error_bound)
    gap_error = abs(r_floor.value - r_ceil.value) * t
    total_error = composed_error + gap_error

    return ApproximateResult(interpolated_value, r_floor.p, total_error, r_floor.config_id)
end

end # module FractionalDepth
