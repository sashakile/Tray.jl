module Tray

include("base.jl")
include("scalar_summary.jl")

# Export core interface
export TrayBase
export ScalarSchema, ScalarSummary

# Re-export generic interface from TrayBase
import .TrayBase: combine, identity
export combine, identity

end # module Tray
