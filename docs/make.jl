module TrayDocs

using Documenter
using Tray

repo_root = dirname(@__DIR__)
generated_dir = joinpath(@__DIR__, "src", "generated")
rm(generated_dir; recursive = true, force = true)
mkpath(generated_dir)

# Mirror the authoritative specifications so Documenter can publish files outside docs/src.
cp(
    joinpath(repo_root, "tray-jl-ears-spec.md"),
    joinpath(generated_dir, "tray-jl-ears-spec.md"),
)
openspec_dir = joinpath(generated_dir, "openspec")
cp(joinpath(repo_root, "openspec"), openspec_dir)

function page_title(path)
    for line in eachline(path)
        if startswith(line, "# ")
            return strip(line[3:end])
        end
    end
    return titlecase(replace(splitext(basename(path))[1], '-' => ' '))
end

function markdown_pages(dir, relative_dir)
    pages = Pair{String,Any}[]
    for entry in sort(readdir(dir))
        path = joinpath(dir, entry)
        relative_path = joinpath(relative_dir, entry)
        if isdir(path)
            children = markdown_pages(path, relative_path)
            isempty(children) ||
                push!(pages, titlecase(replace(entry, '-' => ' ')) => children)
        elseif endswith(entry, ".md") && entry != "AGENTS.md"
            push!(pages, page_title(path) => relative_path)
        end
    end
    return pages
end

openspec_pages = markdown_pages(openspec_dir, joinpath("generated", "openspec"))

makedocs(
    sitename = "Tray.jl",
    authors = "sasha",
    modules = [Tray],
    pages = [
        "Home" => "index.md",
        "API Reference" => "api.md",
        "Specifications" => [
            "EARS Spec" => "generated/tray-jl-ears-spec.md",
            "OpenSpec" => ["Overview" => "specs/index.md", openspec_pages...],
        ],
        "Developer Guide" =>
            ["Architecture" => "dev/architecture.md", "Testing" => "dev/testing.md"],
        "Status" => "status.md",
    ],
)

end
