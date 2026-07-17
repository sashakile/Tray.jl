module RiskTreeDocs

using Documenter
using RiskTree

# Copy EARS spec into docs tree
cp(joinpath(dirname(@__DIR__), "risk-tree-ears-spec.md"),
   joinpath(@__DIR__, "src", "specs", "risk-tree-ears-spec.md");
   force=true)

# Copy OpenSpec specs into docs tree
openspec_src = joinpath(dirname(@__DIR__), "openspec", "changes")
if isdir(openspec_src)
    for change in readdir(openspec_src)
        spec_dir = joinpath(openspec_src, change, "specs")
        if isdir(spec_dir)
            for spec_file in readdir(spec_dir)
                src = joinpath(spec_dir, spec_file)
                dst = joinpath(@__DIR__, "src", "specs", "$(change)-$(spec_file)")
                cp(src, dst; force=true)
            end
        end
    end
end

makedocs(
    sitename = "Tray.jl",
    authors  = "sasha",
    modules  = [RiskTree],
    pages    = [
        "Home" => "index.md",
        "Specifications" => [
            "EARS Spec" => "specs/risk-tree-ears-spec.md",
            "OpenSpec Changes" => "specs/index.md",
        ],
        "API Reference" => [
            "Public API" => "api/public.md",
            "Internal API" => "api/internal.md",
        ],
        "Developer Guide" => [
            "Architecture" => "dev/architecture.md",
            "Testing" => "dev/testing.md",
        ],
        "Status" => "status.md",
    ],
    warnonly = true,
)

deploydocs(
    repo = "github.com/sashakile/Tray.jl.git",
    push_preview = true,
)

end