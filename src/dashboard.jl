# Tray.Dashboard — Optional dashboard model protocol (REQ-27).
#
# Provides a transport-neutral serializable model with latest-wins semantics
# for concurrent requests. Each input change captures a strictly increasing
# revision; only the latest revision publishes; superseded results are discarded.

module Dashboard

import ..Tray: Tree, range_query, ScalarSchema, root, leaf_count, depth
import Base: getproperty, setproperty!

export DashboardModel, get_field, set_field!, subscribe!, execute_query

"""
    DashboardModel{P}

Dashboard model wrapping a tree with latest-wins request protocol.

Fields (accessed via `get_field` / `set_field!`):
- `viewport_range`: `(lo, hi)` tuple of leaf indices, or `nothing`
- `requested_depth`: integer depth or `nothing`
- `request_revision`: monotonically increasing revision counter
- `aggregate`: latest published aggregation result, or `nothing`
- `effective_depth`: depth of the published result, or `nothing`
- `error`: error message from last failed query, or `nothing`
- `result_revision`: revision of the published result
"""
mutable struct DashboardModel{P}
    # Tree reference (immutable during model lifetime)
    tree::Tree{P}

    # Input fields
    viewport_range::Union{Tuple{Int,Int},Nothing}
    requested_depth::Union{Int,Nothing}
    request_revision::Int

    # Output fields (latest published result)
    aggregate::Union{P,Nothing}
    effective_depth::Union{Int,Nothing}
    error::Union{String,Nothing}
    result_revision::Int

    # Change listeners
    listeners::Vector{Function}

    function DashboardModel{P}(tree::Tree{P}) where {P}
        return new{P}(
            tree,
            nothing,  # viewport_range
            nothing,  # requested_depth
            0,        # request_revision
            nothing,  # aggregate
            nothing,  # effective_depth
            nothing,  # error
            0,        # result_revision
            Function[],  # listeners
        )
    end
end

"""
    DashboardModel(tree::Tree{P}) -> DashboardModel{P}

Construct a dashboard model wrapping a tree.
"""
function DashboardModel(tree::Tree{P}) where {P}
    return DashboardModel{P}(tree)
end

# ---------------------------------------------------------------------------
# Field access
# ---------------------------------------------------------------------------

"""
    get_field(model::DashboardModel, field::Symbol)

Read a field from the dashboard model. Valid fields:
`:viewport_range`, `:requested_depth`, `:request_revision`,
`:aggregate`, `:effective_depth`, `:error`, `:result_revision`.
"""
function get_field(model::DashboardModel, field::Symbol)
    if field === :viewport_range
        return model.viewport_range
    elseif field === :requested_depth
        return model.requested_depth
    elseif field === :request_revision
        return model.request_revision
    elseif field === :aggregate
        return model.aggregate
    elseif field === :effective_depth
        return model.effective_depth
    elseif field === :error
        return model.error
    elseif field === :result_revision
        return model.result_revision
    else
        throw(ArgumentError("DashboardModel: unknown field $field"))
    end
end

"""
    set_field!(model::DashboardModel, field::Symbol, value)

Set an input field and increment the request revision.
Valid input fields: `:viewport_range`, `:requested_depth`.

Returns the new request revision.
"""
function set_field!(model::DashboardModel, field::Symbol, value)
    if field === :viewport_range
        model.viewport_range = value
        model.request_revision += 1
        return model.request_revision
    elseif field === :requested_depth
        model.requested_depth = value
        model.request_revision += 1
        return model.request_revision
    else
        throw(ArgumentError("DashboardModel: cannot set field $field"))
    end
end

# ---------------------------------------------------------------------------
# Change notification
# ---------------------------------------------------------------------------

"""
    subscribe!(model::DashboardModel, callback::Function)

Register a change listener. The callback is called with `(model, field, value)`
whenever a field changes (both input sets and result publications).
Returns the listener for later removal.
"""
function subscribe!(model::DashboardModel, callback::Function)
    push!(model.listeners, callback)
    return callback
end

"""
    _notify(model::DashboardModel, field::Symbol, value)

Notify all registered listeners of a field change.
"""
function _notify(model::DashboardModel, field::Symbol, value)
    for listener in model.listeners
        try
            listener(model, field, value)
        catch
            # Silently ignore listener errors per spec
        end
    end
end

# ---------------------------------------------------------------------------
# Query execution with latest-wins semantics
# ---------------------------------------------------------------------------

"""
    execute_query(model::DashboardModel)

Execute a range query based on the current `viewport_range` and `requested_depth`,
then atomically publish the result if this request is still the latest.

Returns `(model.request_revision, model.result_revision)`.

If `viewport_range` is `nothing`, this is a no-op.
If the range or depth is invalid, the error field is set instead of aggregate.
"""
function execute_query(model::DashboardModel)
    # Capture the current request revision at the start
    query_revision = model.request_revision

    # If no viewport is set, nothing to do
    if model.viewport_range === nothing
        return (query_revision, model.result_revision)
    end

    lo, hi = model.viewport_range
    n = leaf_count(model.tree)

    result = nothing
    depth_val = nothing
    error_msg = nothing

    # Validate and execute the query
    try
        if lo < 1 || hi > n || lo > hi
            throw(BoundsError("viewport_range ($lo, $hi) out of bounds [1, $n]"))
        end

        if model.requested_depth !== nothing
            target = model.requested_depth
            max_d = depth(model.tree)
            if target < 0 || target > max_d
                throw(ArgumentError("requested_depth $target out of range [0, $max_d]"))
            end
            result = range_query(model.tree, lo, hi; target_depth = target)
            depth_val = target
        else
            result = range_query(model.tree, lo, hi)
            depth_val = depth(model.tree)
        end
    catch e
        error_msg = sprint(showerror, e)
    end

    # Latest-wins: only publish if this is still the latest request
    if query_revision == model.request_revision
        if error_msg === nothing
            model.aggregate = result
            model.effective_depth = depth_val
            model.error = nothing
        else
            model.aggregate = nothing
            model.effective_depth = nothing
            model.error = error_msg
        end
        model.result_revision = query_revision

        # Notify listeners
        _notify(model, :aggregate, model.aggregate)
        _notify(model, :effective_depth, model.effective_depth)
        _notify(model, :error, model.error)
        _notify(model, :result_revision, model.result_revision)
    end

    return (query_revision, model.result_revision)
end

end # module Dashboard
