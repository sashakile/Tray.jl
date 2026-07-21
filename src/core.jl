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
    canonical_nodes(tree::Tree, lo::Int, hi::Int) -> Vector{Tuple{Int, Int}}

Return the minimal canonical set of (level, index) pairs that exactly cover the
leaf-index range [lo, hi] (1-based, inclusive).

Level 1 = leaves. Higher levels = internal nodes. The result is ordered from
left to right, with node levels non-decreasing.

Uses recursive top-down decomposition: fully-covered nodes are emitted directly,
partial overlap recurses into children.

See REQ-10.
"""
function canonical_nodes(tree::Tree, lo::Int, hi::Int)
    n = leaf_count(tree)
    1 <= lo <= hi <= n ||
        throw(BoundsError("canonical_nodes: [$lo, $hi] out of bounds [1, $n]"))

    nodes = Tuple{Int,Int}[]
    _canonical_visit(tree, depth(tree) + 1, 1, 1, n, lo, hi, nodes)
    return nodes
end

# Recursive helper: visit a node at (level, idx) covering [node_lo, node_hi].
# Collects canonical nodes into `nodes`.
function _canonical_visit(tree, level, idx, node_lo, node_hi, lo, hi, nodes)
    if lo <= node_lo && node_hi <= hi
        # Fully covered by query range: emit this node
        push!(nodes, (level, idx))
        return
    end
    if hi < node_lo || lo > node_hi
        # No overlap
        return
    end
    # Partial overlap: recurse into children
    child_level = level - 1
    if child_level >= 1
        n = leaf_count(tree)
        chunk_size = tree.b^(child_level - 1)
        child_start = (idx - 1) * tree.b + 1
        child_end = min(idx * tree.b, length(tree.levels[child_level]))
        for child_idx = child_start:child_end
            c_lo = (child_idx - 1) * chunk_size + 1
            c_hi = min(child_idx * chunk_size, n)
            _canonical_visit(tree, child_level, child_idx, c_lo, c_hi, lo, hi, nodes)
        end
    end
    return
end

"""
    range_query(tree::Tree{P}, lo::Int, hi::Int; target_depth=nothing) -> P

Fold of leaves in index range [lo, hi] (1-based, inclusive).
When `target_depth` is provided (integer 0..max_depth), uses only canonical
nodes at that depth or above (closer to root). Raises ArgumentError if the
range cannot be exactly represented at the given depth.

See REQ-10, REQ-12, REQ-34.
"""
function range_query(tree::Tree{P}, lo::Int, hi::Int; target_depth = nothing) where {P}
    n = leaf_count(tree)
    1 <= lo <= hi <= n ||
        throw(BoundsError("range_query: [$lo, $hi] out of bounds [1, $n]"))

    max_depth = depth(tree)

    if target_depth !== nothing
        target_depth < 0 &&
            throw(ArgumentError("range_query: target_depth must be ≥ 0, got $target_depth"))
        target_depth > max_depth && throw(
            ArgumentError(
                "range_query: target_depth $target_depth exceeds max depth $max_depth",
            ),
        )

        # Target-depth: depth 0 = root (level max_depth+1), depth d = level (max_depth - d + 1)
        min_level = max_depth - target_depth + 1
        nodes = canonical_nodes(tree, lo, hi)

        # Verify all nodes are at or above the target level
        for (lvl, _) in nodes
            lvl >= min_level || throw(
                ArgumentError(
                    "range_query: range [$lo, $hi] cannot be represented at " *
                    "target_depth $target_depth; node at level $lvl is below target level $min_level",
                ),
            )
        end

        result = TrayBase.identity(tree.schema)
        for (lvl, idx) in nodes
            result = TrayBase.combine(result, tree.levels[lvl][idx])
        end
        return result
    end

    # Standard range query: fold canonical decomposition
    nodes = canonical_nodes(tree, lo, hi)
    result = TrayBase.identity(tree.schema)
    for (lvl, idx) in nodes
        result = TrayBase.combine(result, tree.levels[lvl][idx])
    end
    return result
end

"""
    derived_mean(summary::ScalarSummary) -> Float64

Derive the mean (sum / count) from a ScalarSummary.
Throws DomainError when count is zero.

See REQ-13.
"""
function derived_mean(summary::ScalarSummary{T}) where {T}
    summary.count > 0 || throw(DomainError(summary.count, "derived_mean: count is zero"))
    return summary.sum / summary.count
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
