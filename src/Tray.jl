module Tray

include("base.jl")
include("scalar_summary.jl")
include("attribution_payload.jl")
include("core.jl")
include("axes.jl")
include("incremental.jl")
include("sample_analytics.jl")

# Export core interface
export TrayBase
export ScalarSchema, ScalarSummary
export AttributionSchema,
    AttributionPayload, AttributionConvention, Direct, Allocated, derive_ratio
export Tree,
    root,
    leaf_count,
    depth,
    range_query,
    update,
    update!,
    canonical_nodes,
    derived_mean,
    derived_variance,
    derived_std

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

# Axes exports
export AxisMap,
    AxisIndex, MultiAxisSet, register_axis!, update_axis_map!, get_leaf_ids, intersect_axes

# Lazy tag exports
export LazyTag,
    apply_lazy, compose_lazy, identity_lazy, is_identity_lazy, is_distributive, flush_lazy

# Sample analytics exports
import .SampleAnalytics:
    SamplePayload,
    project_samples,
    moment_quantile,
    regenerate_samples!,
    regenerate_samples,
    dataset_revision,
    AlignedProjectionError,
    MomentQuantileResult
export SamplePayload,
    project_samples,
    moment_quantile,
    regenerate_samples!,
    regenerate_samples,
    dataset_revision,
    AlignedProjectionError,
    MomentQuantileResult

end # module Tray
