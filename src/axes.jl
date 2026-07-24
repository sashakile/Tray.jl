"""
    AxisMap

A revisioned mapping from axis node/cut names to sets of leaf IDs,
with a reverse leaf-ID membership map.

- `node_to_leaves`: each axis cut → sorted vector of leaf IDs
- `revision`: monotonically increasing revision counter
- `leaf_membership`: cached reverse map (leaf ID → list of axis nodes containing it)

See REQ-8.
"""
struct AxisMap
    node_to_leaves::Dict{String,Vector{Int}}
    revision::Int
    leaf_membership::Dict{Int,Vector{String}}
end

"""
    AxisMap(node_to_leaves)

Construct an AxisMap from node→leaf-IDs dict. Computes the reverse membership map.
"""
function AxisMap(node_to_leaves::Dict{String,Vector{Int}}, revision::Int = 1)
    # Validate all leaf IDs are positive and unique within a node
    for (name, ids) in node_to_leaves
        for id in ids
            id >= 1 ||
                throw(ArgumentError("AxisMap: leaf ID $id must be ≥ 1 in node '$name'"))
        end
    end

    # Build reverse membership map
    leaf_membership = Dict{Int,Vector{String}}()
    for (name, ids) in node_to_leaves
        for id in ids
            if haskey(leaf_membership, id)
                push!(leaf_membership[id], name)
            else
                leaf_membership[id] = [name]
            end
        end
    end

    return AxisMap(node_to_leaves, revision, leaf_membership)
end

"""
    AxisIndex

One independent axis (categorical or ordered hierarchy) over shared leaf IDs.
Each axis has its own name, revisioned map, and aggregation tree.

- `name`: unique identifier for this axis
- `axis_map`: revisioned node-ID to leaf-ID mapping
- `tree`: aggregation tree over this axis's leaf ordering
- `revision`: axis-local revision

See REQ-8, REQ-25.
"""
struct AxisIndex{P,S}
    name::String
    axis_map::AxisMap
    tree::Tree{P,S}
    revision::Int
end

"""
    AxisIndex(name, axis_map, tree)

Convenience constructor with revision=1.
"""
function AxisIndex(name::String, axis_map::AxisMap, tree::Tree{P,S}) where {P,S}
    return AxisIndex{P,S}(name, axis_map, tree, 1)
end

"""
    MultiAxisSet{P,S}

A collection of independent axes sharing one leaf source and one dataset revision.
The shared tree is authoritative for leaf values; each axis has its own
aggregation index and membership map.

Use `register_axis!` to add axes and `intersect_axes` to query across them.

See REQ-8, REQ-25, REQ-39.
"""
mutable struct MultiAxisSet{P,S}
    tree::Tree{P,S}
    axes::Dict{String,AxisIndex{P,S}}
    revision::Int  # dataset revision (incremented when tree or any axis updates)
end

"""
    MultiAxisSet(tree)

Create an empty MultiAxisSet sharing the given tree as leaf source.
"""
function MultiAxisSet(tree::Tree{P,S}) where {P,S}
    return MultiAxisSet{P,S}(tree, Dict{String,AxisIndex{P,S}}(), 1)
end

"""
    register_axis!(mas::MultiAxisSet, name::String, axis_map::AxisMap) -> AxisIndex

Register a new axis by name with the given membership map.
The axis creates a new tree with the same schema as the shared tree,
ordered according to the axis map's leaf ordering.
Returns the newly created AxisIndex.

Raises ArgumentError if an axis with this name already exists.

See REQ-8.
"""
function register_axis!(mas::MultiAxisSet{P,S}, name::String, axis_map::AxisMap) where {P,S}
    haskey(mas.axes, name) &&
        throw(ArgumentError("register_axis!: axis '$name' already exists"))

    # Build leaf ordering from axis map: collect all unique leaf IDs mentioned
    all_ids = Int[]
    seen = Set{Int}()
    for (_, ids) in sort(collect(axis_map.node_to_leaves); by = first)
        for id in ids
            if !(id in seen)
                push!(seen, id)
                push!(all_ids, id)
            end
        end
    end

    # Extract leaf payloads in axis order from the shared tree
    n = leaf_count(mas.tree)
    axis_leaves = [mas.tree.levels[1][id] for id in all_ids]

    # Create a new tree for this axis
    axis_tree = Tree(axis_leaves; b = mas.tree.b, schema = mas.tree.schema)

    axis_idx = AxisIndex(name, axis_map, axis_tree)
    mas.axes[name] = axis_idx
    mas.revision += 1
    return axis_idx
end

"""
    update_axis_map!(mas::MultiAxisSet, name::String, axis_map::AxisMap)

Replace the membership map of an existing axis. Increments the axis revision.

Raises ArgumentError if the axis doesn't exist.

See REQ-25.
"""
function update_axis_map!(
    mas::MultiAxisSet{P,S},
    name::String,
    axis_map::AxisMap,
) where {P,S}
    haskey(mas.axes, name) ||
        throw(ArgumentError("update_axis_map!: axis '$name' not found"))

    old = mas.axes[name]
    new_revision = old.revision + 1

    # Rebuild the axis tree with the new leaf ordering
    all_ids = Int[]
    seen = Set{Int}()
    for (_, ids) in sort(collect(axis_map.node_to_leaves); by = first)
        for id in ids
            if !(id in seen)
                push!(seen, id)
                push!(all_ids, id)
            end
        end
    end

    axis_leaves = [mas.tree.levels[1][id] for id in all_ids]
    axis_tree = Tree(axis_leaves; b = mas.tree.b, schema = mas.tree.schema)

    mas.axes[name] = AxisIndex{P,S}(name, axis_map, axis_tree, new_revision)
    mas.revision += 1
    return nothing
end

"""
    get_leaf_ids(axis::AxisIndex, node::String) -> Vector{Int}

Return the leaf IDs belonging to a named axis node/cut.
Raises KeyError if the node doesn't exist.
"""
function get_leaf_ids(axis::AxisIndex, node::String)
    return axis.axis_map.node_to_leaves[node]
end

"""
    intersect_axes(mas::MultiAxisSet, queries::Vector{Tuple{String,String}}) -> P

Perform a cross-axis intersection query. Each tuple is (axis_name, node_name).

Algorithm:
1. Snapshot all requested axis maps plus the shared tree at one revision
2. Reject cross-version combinations
3. Obtain each cut's leaf-ID set
4. Compute exact set intersection
5. Sort resulting IDs by array order
6. Coalesce consecutive indices into maximal ranges
7. Canonically decompose each range
8. Fold nodes left-to-right

Raises ArgumentError on cross-version inputs or unknown axes/nodes.

See REQ-39.
"""
function intersect_axes(
    mas::MultiAxisSet{P,S},
    queries::Vector{Tuple{String,String}},
) where {P,S}
    isempty(queries) && throw(ArgumentError("intersect_axes: at least one query required"))

    # Snapshot the tree revision
    dataset_revision = mas.revision

    # Collect leaf ID sets from each queried axis
    leaf_sets = Vector{Set{Int}}()
    for (axis_name, node_name) in queries
        haskey(mas.axes, axis_name) ||
            throw(ArgumentError("intersect_axes: unknown axis '$axis_name'"))
        axis = mas.axes[axis_name]
        haskey(axis.axis_map.node_to_leaves, node_name) || throw(
            ArgumentError("intersect_axes: unknown node '$node_name' on axis '$axis_name'"),
        )

        leaf_ids = Set{Int}(axis.axis_map.node_to_leaves[node_name])
        push!(leaf_sets, leaf_ids)
    end

    # Compute exact set intersection of stable leaf IDs
    intersection = leaf_sets[1]
    for s in leaf_sets[2:end]
        intersection = intersect(intersection, s)
    end

    # Convert stable IDs to current array ranks using the tree's leaf_id mapping
    current_ranks = Int[]
    for id in intersection
        rank = leaf_index_by_id(mas.tree, id)
        rank > 0 && push!(current_ranks, rank)
    end
    sort!(current_ranks)

    # Coalesce consecutive indices into maximal ranges
    ranges = Tuple{Int,Int}[]
    i = 1
    while i <= length(current_ranks)
        start_id = current_ranks[i]
        end_id = start_id
        while i < length(current_ranks) && current_ranks[i+1] == end_id + 1
            end_id = current_ranks[i+1]
            i += 1
        end
        push!(ranges, (start_id, end_id))
        i += 1
    end

    # Canonically decompose each range and fold
    isempty(ranges) && return TrayBase.identity(mas.tree.schema)

    result = TrayBase.identity(mas.tree.schema)
    for (lo, hi) in ranges
        nodes = canonical_nodes(mas.tree, lo, hi)
        for (lvl, idx) in nodes
            result = TrayBase.combine(result, mas.tree.levels[lvl][idx])
        end
    end

    return result
end
