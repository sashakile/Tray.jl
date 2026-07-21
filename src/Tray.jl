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
    update_with_strategy
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
    update_with_strategy

# Re-export generic interface from TrayBase
import .TrayBase: combine, identity
export combine, identity

end # module Tray
