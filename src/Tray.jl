module Tray

include("base.jl")
include("scalar_summary.jl")
include("attribution_payload.jl")

# Export core interface
export TrayBase
export ScalarSchema, ScalarSummary
export AttributionSchema,
    AttributionPayload, AttributionConvention, Direct, Allocated, derive_ratio

# Re-export generic interface from TrayBase
import .TrayBase: combine, identity
export combine, identity

end # module Tray
