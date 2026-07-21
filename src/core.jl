"""
    Tree{P, S}

Balanced n-ary aggregation tree over payload type `P` with schema `S`.

- `P` — payload type (must implement `TrayBase.combine` and `TrayBase.identity`)
- `S` — schema type
- `b` — branching factor (≥ 2)
- `levels` — bottom-up levels: `levels[1]` = leaves, `levels[end]` = root
- `schema` — schema bound to this tree, used for identity construction

Leaf IDs are immutable 1-based current array ranks.
Construction folds `combine` over groups of `b` children deterministically.

See REQ-1, REQ-2, REQ-3, REQ-42.
"""
struct Tree{P,S}
    b::Int
    levels::Vector{Vector{P}}
    schema::S

    function Tree{P,S}(b::Int, levels::Vector{Vector{P}}, schema::S) where {P,S}
        b >= 2 || throw(ArgumentError("branching factor b must be ≥ 2, got $b"))
        return new{P,S}(b, levels, schema)
    end
end

"""
    Tree(leaves::Vector{P}; b=2, schema)

Construct a tree from leaf payloads with branching factor `b`.
Validates:
- Non-empty leaves
- Branching factor b ≥ 2
- Every leaf matches the tree schema (REQ-2)

Builds all levels bottom-up using `combine` in O(n) time (REQ-42).
Leaf IDs are 1-based current array ranks (immutable within one revision).
"""
function Tree(leaves::Vector{P}; b::Int = 2, schema) where {P}
    isempty(leaves) && throw(ArgumentError("Tree: must have at least one leaf"))
    b >= 2 || throw(ArgumentError("Tree: branching factor b must be ≥ 2, got $b"))

    # Schema validation (REQ-2): check each leaf is compatible with tree schema
    id = TrayBase.identity(schema)
    for (i, leaf) in enumerate(leaves)
        combined_left = TrayBase.combine(id, leaf)
        combined_right = TrayBase.combine(leaf, id)
        if combined_left != leaf || combined_right != leaf
            throw(
                ArgumentError(
                    "Tree: leaf $i schema does not match tree schema; " *
                    "identity law violation with tree identity",
                ),
            )
        end
    end

    levels = [copy(leaves)]
    current = leaves
    while length(current) > 1
        next_level = P[]
        for i = 1:b:length(current)
            chunk = current[i:min(i+b-1, end)]
            combined = reduce(TrayBase.combine, chunk)
            push!(next_level, combined)
        end
        push!(levels, next_level)
        current = next_level
    end

    return Tree{P,typeof(schema)}(b, levels, schema)
end

"""
    root(tray::Tree) -> P

The root aggregate (fold of all leaves).
"""
root(tray::Tree{P}) where {P} = tray.levels[end][1]

"""
    leaf_count(tray::Tree) -> Int
"""
leaf_count(tray::Tree) = length(tray.levels[1])

"""
    depth(tray::Tree) -> Int

Edge distance from root (depth 0) to leaves.
"""
depth(tray::Tree) = length(tray.levels) - 1

"""
    range_query(tray::Tree{P}, lo::Int, hi::Int) -> P

Fold of leaves in index range `[lo, hi]` (1-based, inclusive).
"""
function range_query(tray::Tree{P}, lo::Int, hi::Int) where {P}
    n = leaf_count(tray)
    1 <= lo <= hi <= n ||
        throw(BoundsError("range_query: [$lo, $hi] out of bounds [1, $n]"))

    # Simple canonical decomposition: walk levels top-down
    # For the tracer bullet, start with a direct fold of leaves
    # (optimization: use canonical decomposition for larger trees)
    result = TrayBase.identity(tray.schema)
    for i = lo:hi
        result = TrayBase.combine(result, tray.levels[1][i])
    end
    return result
end

"""
    update!(tray::Tree{P}, index::Int, value::P) -> P

Replace a leaf and recompute its ancestors.
Returns the new root.
"""
function update!(tray::Tree{P}, index::Int, value::P) where {P}
    n = leaf_count(tray)
    1 <= index <= n || throw(BoundsError("update!: index $index out of bounds [1, $n]"))

    # Update leaf
    tray.levels[1][index] = value

    # Recompute ancestors bottom-up
    current = tray.levels[1]
    for level_idx = 2:length(tray.levels)
        next_level = tray.levels[level_idx]
        child_start = 1
        for i in eachindex(next_level)
            chunk = current[child_start:min(child_start+tray.b-1, end)]
            next_level[i] = reduce(TrayBase.combine, chunk)
            child_start += tray.b
        end
        current = next_level
    end

    return root(tray)
end
