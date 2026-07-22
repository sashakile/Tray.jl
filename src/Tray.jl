module Tray

include("base.jl")
include("scalar_summary.jl")
include("attribution_payload.jl")
include("core.jl")
include("incremental.jl")

# Export core interface
export TrayBase
export ScalarSchema, ScalarSummary
export AttributionSchema,
    AttributionPayload, AttributionConvention, Direct, Allocated, derive_ratio
export Tree,
    root, leaf_count, depth, range_query, update, update!, canonical_nodes, derived_mean

# Incremental exports
import .Incremental:
    Change,
    ScalarSummaryChange,
    zero_change,
    valid_change,
    apply_change,
    compose_change,
    AbstractProvider,
    DefaultProvider,
    available,
    retrieve_ir,
    CoverageLevel,
    CovCovered,
    CovBoundary,
    CovRejected,
    coverage_join,
    Diagnostic,
    AnalysisResult,
    Derived,
    Rejected,
    derive,
    UpdateSnapshot,
    UpdateStrategy,
    apply_strategy,
    validate_with_oracle,
    update_with_strategy,
    try_apply_strategy,
    update_with_boundary_detection
export Change,
    ScalarSummaryChange,
    zero_change,
    valid_change,
    apply_change,
    compose_change,
    AbstractProvider,
    DefaultProvider,
    available,
    retrieve_ir,
    CoverageLevel,
    CovCovered,
    CovBoundary,
    CovRejected,
    coverage_join,
    Diagnostic,
    AnalysisResult,
    Derived,
    Rejected,
    derive,
    UpdateSnapshot,
    UpdateStrategy,
    apply_strategy,
    validate_with_oracle,
    update_with_strategy,
    try_apply_strategy,
    update_with_boundary_detection

# Re-export generic interface from TrayBase
import .TrayBase: combine, identity, reweight
export combine, identity, reweight

# Structural mutation exports
export insert!, insert, remove!, remove, reweight_subtree

# Lazy tag exports
export LazyTag,
    apply_lazy, compose_lazy, identity_lazy, is_identity_lazy, is_distributive, flush_lazy

end # module Tray
