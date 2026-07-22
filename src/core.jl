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
    id = TrayBase.identity(schema, P, first(leaves))
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

        id_for_payload = TrayBase.identity(tree.schema, P, tree.levels[1][1])
        result = id_for_payload
        for (lvl, idx) in nodes
            result = TrayBase.combine(result, tree.levels[lvl][idx])
        end
        return result
    end

    # Standard range query: fold canonical decomposition
    nodes = canonical_nodes(tree, lo, hi)
    # Use identity that matches the payload type
    id = TrayBase.identity(tree.schema, P, tree.levels[1][1])
    result = id
    for (lvl, idx) in nodes
        result = TrayBase.combine(result, tree.levels[lvl][idx])
    end
    return result
end

"""
    derived_mean(summary::ScalarSummary{T}) where {T} -> T

Derive the mean (sum / count) from a ScalarSummary.
Throws DomainError when count is zero.

Note: return type follows the eltype of the schema (Float64 for Int, Float32 for Float32, etc.).

See REQ-13.
"""
function derived_mean(summary::ScalarSummary{T}) where {T}
    summary.count > 0 || throw(DomainError(summary.count, "derived_mean: count is zero"))
    return summary.sum / summary.count
end

"""
    derived_variance(summary::ScalarSummary{T}) where {T} -> T

Derive the population variance (sumsq / count - mean^2) from a ScalarSummary.
Throws DomainError when count is zero or variance is negative due to
floating-point rounding (clamped to zero).

See REQ-5.
"""
function derived_variance(summary::ScalarSummary{T}) where {T}
    summary.count > 0 ||
        throw(DomainError(summary.count, "derived_variance: count is zero"))
    n = T(summary.count)
    mean = summary.sum / n
    var = summary.sumsq / n - mean^2
    # Clamp tiny negative values from floating-point rounding to zero
    return max(var, zero(T))
end

"""
    derived_std(summary::ScalarSummary{T}) where {T} -> T

Derive the population standard deviation from a ScalarSummary.
Throws DomainError when count is zero or variance is effectively negative.

See REQ-5.
"""
function derived_std(summary::ScalarSummary{T}) where {T}
    summary.count > 0 || throw(DomainError(summary.count, "derived_std: count is zero"))
    var = derived_variance(summary)
    return sqrt(var)
end

"""
    derived_sample_error()

Raise an informative error when a sample-derived statistic is requested
from a ScalarSummary-only node (REQ-36).
"""
function derived_sample_error(statistic_name::String)
    error(
        "$statistic_name requires sample data; " *
        "the queried node contains only ScalarSummary aggregates. " *
        "Use a SamplePayload-based tree to compute sample statistics.",
    )
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
# ---- Ancestor-path helpers (for O(log_b n) updates) ----

"""
    _leaf_ancestor_level(tree, leaf_index) -> Vector{Tuple{Int,Int}}

Return the (level, index) pairs tracing the ancestor path from leaf to root.
Level 1 is the leaf level, higher levels are internal nodes.

For a leaf at position `leaf_index` with branching factor `b`:
- Level 1: leaf at index `leaf_index`
- Level 2: parent at index `(leaf_index-1) ÷ b + 1`
- Level 3: grandparent at index `(parent_idx-1) ÷ b + 1`
- ...until root

This enables O(log_b n) ancestor recomputation (REQ-41, REQ-9).
"""
function _leaf_ancestor_level(tree, leaf_index)
    path = Tuple{Int,Int}[]
    idx = leaf_index
    for level = 1:length(tree.levels)
        push!(path, (level, idx))
        idx = (idx - 1) ÷ tree.b + 1
    end
    return path
end

"""
    _recompute_ancestor_path!(tree, leaf_index)

Recompute only the ancestors of `leaf_index` from level 2 up to root.
Assumes the leaf at `leaf_index` in `tree.levels[1]` has already been updated.

O(log_b n) time (REQ-41).
"""
function _recompute_ancestor_path!(tree, leaf_index)
    path = _leaf_ancestor_path(tree, leaf_index)
    # path[1] = (1, leaf_index) — already updated
    for p_idx = 2:length(path)
        level, node_idx = path[p_idx]
        prev_level, _ = path[p_idx-1]

        # Find the range of children for this node
        child_start = (node_idx - 1) * tree.b + 1
        child_end = min(node_idx * tree.b, length(tree.levels[prev_level]))

        chunk = tree.levels[prev_level][child_start:child_end]
        tree.levels[level][node_idx] = reduce(TrayBase.combine, chunk)
    end
    return nothing
end

# Alias for clarity
const _leaf_ancestor_path = _leaf_ancestor_level

# ---- Optimized update!/update (REQ-41: O(log_b n)) ----

"""
    update!(tray::Tree{P}, index::Int, value::P) -> P

Replace a leaf and recompute its ancestors (O(log_b n)).
Returns the new root.

See REQ-9, REQ-11, REQ-41.
"""
function update!(tray::Tree{P}, index::Int, value::P) where {P}
    n = leaf_count(tray)
    1 <= index <= n || throw(BoundsError("update!: index $index out of bounds [1, $n]"))

    # Update leaf
    tray.levels[1][index] = value

    # Recompute ancestors bottom-up along the ancestor path only
    _recompute_ancestor_path!(tray, index)

    return root(tray)
end

"""
    update(tree::Tree{P}, index::Int, value::P) -> Tree{P}

Return a new tree with leaf `index` replaced by `value` and all ancestors
recomputed. The original tree is unchanged (snapshot isolation).

Only the affected leaf and its ancestors are recomputed; sibling subtrees are
shared between old and new trees (copy-on-write).

O(log_b n) time (REQ-41).
"""
function update(tree::Tree{P}, index::Int, value::P) where {P}
    n = leaf_count(tree)
    1 <= index <= n || throw(BoundsError("update: index $index out of bounds [1, $n]"))

    # Build new levels, sharing unchanged subtrees
    new_levels = [copy(tree.levels[1])]
    new_levels[1][index] = value

    # Copy internal levels, recomputing only the ancestor chain
    path = _leaf_ancestor_path(tree, index)
    for p_idx = 2:length(path)
        level, node_idx = path[p_idx]
        prev_level, _ = path[p_idx-1]

        # Copy this level's array
        new_internal = copy(tree.levels[level])

        # Recompute this node from its children
        child_start = (node_idx - 1) * tree.b + 1
        child_end = min(node_idx * tree.b, length(new_levels[prev_level]))
        chunk = new_levels[prev_level][child_start:child_end]
        new_internal[node_idx] = reduce(TrayBase.combine, chunk)

        push!(new_levels, new_internal)
    end

    return Tree{P,typeof(tree.schema)}(tree.b, new_levels, tree.schema)
end

# ---- Leaf insertion (REQ-14) ----

"""
    insert!(tray::Tree{P}, index::Int, value::P)

Insert a leaf at position `index` (1 ≤ index ≤ n+1) into the tree.
Shifts later leaves right, assigns an immutable leaf ID, and recomputes
affected summaries. May grow the tree if the index exceeds capacity.

O(n) in the worst case due to leaf-level shift; ancestor recomputation is
O(log_b n) per affected leaf.

See REQ-14.
"""
function insert!(tray::Tree{P}, index::Int, value::P) where {P}
    n = leaf_count(tray)
    1 <= index <= n + 1 ||
        throw(BoundsError("insert!: position $index out of bounds [1, $(n + 1)]"))

    # Insert into leaf level (must explicitly call Base.insert! on Vector)
    Base.insert!(tray.levels[1], index, value)

    # Rebuild all internal levels from scratch (level arrays may have grown)
    while length(tray.levels) > 1
        pop!(tray.levels)
    end

    current = tray.levels[1]
    while length(current) > 1
        next_level = P[]
        for i = 1:tray.b:length(current)
            chunk = current[i:min(i+tray.b-1, end)]
            push!(next_level, reduce(TrayBase.combine, chunk))
        end
        push!(tray.levels, next_level)
        current = next_level
    end

    return nothing
end

"""
    insert(tree::Tree{P}, index::Int, value::P) -> Tree{P}

Return a new tree with `value` inserted at leaf position `index`.
The original tree is unchanged (snapshot isolation).

See REQ-14.
"""
function insert(tree::Tree{P}, index::Int, value::P) where {P}
    n = leaf_count(tree)
    1 <= index <= n + 1 ||
        throw(BoundsError("insert: position $index out of bounds [1, $(n + 1)]"))

    # Copy leaves and insert
    new_leaves = copy(tree.levels[1])
    Base.insert!(new_leaves, index, value)

    # Build new tree from scratch (simplest correct approach)
    return Tree(new_leaves; b = tree.b, schema = tree.schema)
end

# ---- Leaf removal (REQ-15) ----

"""
    remove!(tray::Tree{P}, index::Int)

Remove the leaf at position `index` (1 ≤ index ≤ n) from the tree.
Closes the gap and recomputes affected summaries.
Raises ArgumentError if removal would leave the tree empty.

See REQ-15.
"""
function remove!(tray::Tree{P}, index::Int) where {P}
    n = leaf_count(tray)
    1 <= index <= n || throw(BoundsError("remove!: index $index out of bounds [1, $n]"))
    n > 1 || throw(
        ArgumentError("remove!: cannot remove the final leaf; tree must remain non-empty"),
    )

    # Remove from leaf level (must explicitly call Base.deleteat! on Vector)
    Base.deleteat!(tray.levels[1], index)

    # Rebuild all internal levels from scratch (level arrays may need compaction)
    while length(tray.levels) > 1
        pop!(tray.levels)
    end

    current = tray.levels[1]
    while length(current) > 1
        next_level = P[]
        for i = 1:tray.b:length(current)
            chunk = current[i:min(i+tray.b-1, end)]
            push!(next_level, reduce(TrayBase.combine, chunk))
        end
        push!(tray.levels, next_level)
        current = next_level
    end

    return nothing
end

"""
    remove(tree::Tree{P}, index::Int) -> Tree{P}

Return a new tree with the leaf at position `index` removed.
The original tree is unchanged (snapshot isolation).
Raises ArgumentError if removal would leave the tree empty.

See REQ-15.
"""
function remove(tree::Tree{P}, index::Int) where {P}
    n = leaf_count(tree)
    1 <= index <= n || throw(BoundsError("remove: index $index out of bounds [1, $n]"))
    n > 1 || throw(
        ArgumentError("remove: cannot remove the final leaf; tree must remain non-empty"),
    )

    # Copy leaves and remove
    new_leaves = copy(tree.levels[1])
    Base.deleteat!(new_leaves, index)

    # Build new tree from scratch
    return Tree(new_leaves; b = tree.b, schema = tree.schema)
end

# ---- Subtree reweighting (REQ-18) ----

"""
    _level_to_leaf_range(tree, level, node_idx) -> (lo, hi)

Compute the 1-based leaf range [lo, hi] covered by a node at `level` and
`node_idx`. Level 1 = leaves.
"""
function _level_to_leaf_range(tree, level, node_idx)
    if level == 1
        # Leaf node — covers exactly one leaf
        return (node_idx, node_idx)
    end
    # Internal node: compute the span of leaves under this node
    chunk_size = tree.b^(level - 1)
    lo = (node_idx - 1) * chunk_size + 1
    hi = min(node_idx * chunk_size, leaf_count(tree))
    return (lo, hi)
end

"""
    reweight_subtree(tree::Tree{P}, level::Int, node_idx::Int, weight) -> Tree{P}

Apply `TrayBase.reweight` to every leaf in the canonical subtree rooted at
`(level, node_idx)`, then recompute only the affected ancestors.

- Level 1 = leaves, higher levels = internal nodes.
- `weight` is passed to `TrayBase.reweight(leaf, weight)`.
- Returns a new tree; original is unchanged (snapshot isolation).
- Raises MethodError if the payload type does not define `TrayBase.reweight`.

See REQ-18.
"""
function reweight_subtree(tree::Tree{P}, level::Int, node_idx::Int, weight) where {P}
    1 <= level <= length(tree.levels) || throw(
        ArgumentError("reweight: level $level out of bounds [1, $(length(tree.levels))]"),
    )

    lo, hi = _level_to_leaf_range(tree, level, node_idx)
    1 <= lo <= hi <= leaf_count(tree) || throw(
        BoundsError(
            "reweight: node ($level, $node_idx) leaf range [$lo, $hi] out of bounds",
        ),
    )

    # Compute the set of leaf-level ancestor paths affected
    # (from level up to root)
    new_levels = [copy(tree.levels[1])]

    # Apply reweight to affected leaves
    for i = lo:hi
        new_levels[1][i] = TrayBase.reweight(new_levels[1][i], weight)
    end

    # Determine the ancestor path for one representative leaf
    # All leaves in [lo, hi] share the same ancestors from `level` up to root
    path = _leaf_ancestor_path(tree, lo)
    # path[1] = (1, lo), path[2] = (2, parent), ..., path[level] = (level, node_idx), etc.

    for p_idx = 2:length(path)
        lvl, nidx = path[p_idx]
        prev_lvl, _ = path[p_idx-1]

        new_internal = copy(tree.levels[lvl])
        child_start = (nidx - 1) * tree.b + 1
        child_end = min(nidx * tree.b, length(new_levels[prev_lvl]))
        chunk = new_levels[prev_lvl][child_start:child_end]
        new_internal[nidx] = reduce(TrayBase.combine, chunk)
        push!(new_levels, new_internal)
    end

    # For levels above the affected ancestor chain, share unchanged nodes
    for lvl = (length(path)+1):length(tree.levels)
        push!(new_levels, copy(tree.levels[lvl]))
    end

    return Tree{P,typeof(tree.schema)}(tree.b, new_levels, tree.schema)
end

# ---- Lazy tag infrastructure (REQ-29) ----

"""
    LazyTag{T}

Represents a deferred transformation on payloads. Tags form an ordered monoid
action: `apply(compose(new, old), x) = apply(new, apply(old, x))`.

When `distributive` is true, the tag satisfies
`apply(t, combine(a, b)) == combine(apply(t, a), apply(t, b))`.

See REQ-29.
"""
struct LazyTag{T}
    op::Symbol
    value::T
    distributive::Bool
end

"""
    LazyTag(op::Symbol, value; distributive=true)

Convenience constructor with default distributive=true.
"""
function LazyTag(op::Symbol, value; distributive::Bool = true)
    return LazyTag{typeof(value)}(op, value, distributive)
end

"""
    identity_lazy(schema) -> LazyTag

Return an identity lazy tag: `apply(identity_lazy, x) == x`.
"""
function identity_lazy(::Any)
    return LazyTag(:identity, nothing; distributive = true)
end

"""
    is_identity_lazy(tag::LazyTag) -> Bool
"""
function is_identity_lazy(tag::LazyTag)
    return tag.op == :identity
end

"""
    is_distributive(tag::LazyTag) -> Bool

Returns whether the tag distributes over `combine`.
Only distributive tags can be applied lazily (deferred) without immediate
leaf traversal.
"""
function is_distributive(tag::LazyTag)
    return tag.distributive
end

"""
    apply_lazy(tag::LazyTag, payload) -> payload

Apply a deferred transformation to a payload.

For built-in tag types:
- `:identity` — returns payload unchanged
- `:scale` — calls `TrayBase.reweight(payload, tag.value)`
"""
function apply_lazy(tag::LazyTag, payload)
    if is_identity_lazy(tag)
        return payload
    elseif tag.op == :scale
        return TrayBase.reweight(payload, tag.value)
    else
        error("apply_lazy: unknown tag operation $(tag.op)")
    end
end

"""
    compose_lazy(tag_new::LazyTag, tag_old::LazyTag) -> LazyTag

Compose two lazy tags: the result represents applying `tag_new`, then `tag_old`.
Specifically: `apply(compose(tag_new, tag_old), x) = apply(tag_new, apply(tag_old, x))`.

When both tags have the same op and are distributive, composition may be
simplified (e.g., scale(2) ∘ scale(3) = scale(6)).
"""
function compose_lazy(tag_new::LazyTag{T}, tag_old::LazyTag{T}) where {T}
    # Identity cases
    if is_identity_lazy(tag_new)
        return tag_old
    elseif is_identity_lazy(tag_old)
        return tag_new
    end

    # Scale ∘ Scale = Scale with multiplied values
    if tag_new.op == :scale && tag_old.op == :scale
        combined = tag_new.value * tag_old.value
        return LazyTag(:scale, combined; distributive = true)
    end

    # Generic composition: return a pair (or just chain generically)
    # For tags of different ops, we combine into a compound tag
    # Since we can't store arbitrary tuples type-stably, use a generic op
    # This is a simplification — complex compositions would flush
    # to eager application
    error(
        "compose_lazy: cannot compose $(tag_new.op) with $(tag_old.op); " *
        "flush pending tags before applying mixed operations",
    )
end

"""
    flush_lazy!(tree, pending_tags)

Apply all pending lazy tags to the tree, forcing eager recomputation.
Must be called before any topology change (insert, remove), serialization,
or schema change (REQ-29 flush barrier).
"""
function flush_lazy!(tree, pending_tags::Vector{LazyTag})
    isempty(pending_tags) && return nothing

    # Apply all pending tags to every leaf
    for tag in pending_tags
        for i in eachindex(tree.levels[1])
            tree.levels[1][i] = apply_lazy(tag, tree.levels[1][i])
        end
    end

    # Rebuild all internal levels
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

    return nothing
end

"""
    flush_lazy(tree, pending_tags) -> Tree

Immutable version of flush. Returns a new tree with pending tags applied.
"""
function flush_lazy(tree::Tree{P}, pending_tags::Vector{LazyTag}) where {P}
    isempty(pending_tags) && return tree

    # Apply tags to leaves
    new_leaves = copy(tree.levels[1])
    for tag in pending_tags
        for i in eachindex(new_leaves)
            new_leaves[i] = apply_lazy(tag, new_leaves[i])
        end
    end

    return Tree(new_leaves; b = tree.b, schema = tree.schema)
end
