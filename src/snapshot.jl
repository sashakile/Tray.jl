# Tray.Snapshot — Immutable snapshot epoch wrapping a tree with a monotonically
# increasing revision counter. Every mutation publishes a new SnapshotEpoch; reads
# pin one revision.
#
# Provides:
#   SnapshotEpoch(tree) — wrap a tree at revision 1
#   revision(snap) — current snapshot revision
#   Read operations: root, leaf_count, depth, range_query, canonical_nodes, leaf_at
#   Mutation operations: update, insert, remove, reweight_subtree, flush_lazy
#   publish!(ref, new_snap) — atomic exchange of the active snapshot
#   publish_with_rollback(f, ref) — atomic publish with rollback on failure

module Snapshot

import ..Tray:
    Tree,
    root,
    leaf_count,
    depth,
    range_query,
    canonical_nodes,
    update,
    insert,
    remove,
    reweight_subtree,
    flush_lazy

export SnapshotEpoch, revision, publish!, leaf_at

"""
    SnapshotEpoch(tree::Tree{P,S}) -> SnapshotEpoch{P,S}

Wrap a tree at revision 1.
"""
struct SnapshotEpoch{P,S}
    tree::Tree{P,S}
    revision::Int

    function SnapshotEpoch{P,S}(tree::Tree{P,S}, revision::Int) where {P,S}
        revision >= 1 ||
            throw(ArgumentError("SnapshotEpoch revision must be ≥ 1, got $revision"))
        return new{P,S}(tree, revision)
    end
end

function SnapshotEpoch(tree::Tree{P,S}) where {P,S}
    return SnapshotEpoch{P,S}(tree, 1)
end

revision(snap::SnapshotEpoch) = snap.revision
root(snap::SnapshotEpoch) = root(snap.tree)
leaf_count(snap::SnapshotEpoch) = leaf_count(snap.tree)
depth(snap::SnapshotEpoch) = depth(snap.tree)

function range_query(snap::SnapshotEpoch, start_idx::Int, end_idx::Int)
    return range_query(snap.tree, start_idx, end_idx)
end

function canonical_nodes(snap::SnapshotEpoch, start_idx::Int, end_idx::Int)
    return canonical_nodes(snap.tree, start_idx, end_idx)
end

function leaf_at(snap::SnapshotEpoch, index::Int)
    n = leaf_count(snap)
    1 <= index <= n || throw(BoundsError("leaf_at: index $index out of bounds [1, $n]"))
    return snap.tree.levels[1][index]
end

function update(snap::SnapshotEpoch{P}, index::Int, value::P) where {P}
    new_tree = update(snap.tree, index, value)
    return SnapshotEpoch{P,typeof(snap.tree.schema)}(new_tree, snap.revision + 1)
end

function insert(snap::SnapshotEpoch{P}, index::Int, value::P) where {P}
    new_tree = insert(snap.tree, index, value)
    return SnapshotEpoch{P,typeof(snap.tree.schema)}(new_tree, snap.revision + 1)
end

function remove(snap::SnapshotEpoch{P}, index::Int) where {P}
    new_tree = remove(snap.tree, index)
    return SnapshotEpoch{P,typeof(snap.tree.schema)}(new_tree, snap.revision + 1)
end

function reweight_subtree(
    snap::SnapshotEpoch{P},
    level::Int,
    node_idx::Int,
    weight,
) where {P}
    new_tree = reweight_subtree(snap.tree, level, node_idx, weight)
    return SnapshotEpoch{P,typeof(snap.tree.schema)}(new_tree, snap.revision + 1)
end

function flush_lazy(snap::SnapshotEpoch{P}, pending_tags) where {P}
    new_tree = flush_lazy(snap.tree, pending_tags)
    return SnapshotEpoch{P,typeof(snap.tree.schema)}(new_tree, snap.revision + 1)
end

function publish!(ref::Ref{SnapshotEpoch{P,S}}, new_snap::SnapshotEpoch{P,S}) where {P,S}
    ref[] = new_snap
    return new_snap
end

function publish_with_rollback(f, ref::Ref{SnapshotEpoch{P,S}}) where {P,S}
    current = ref[]
    try
        new_snap = f(current)
        return publish!(ref, new_snap)
    catch
        rethrow()
    end
end

end # module Snapshot
