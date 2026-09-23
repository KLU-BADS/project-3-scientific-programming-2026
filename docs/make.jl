using Documenter
using DocumenterMermaid
using DocumenterPlantUML
using DocumenterMermaid
using Project3

# Doctests run in a bare module, so the package has to be brought into scope
# for them. Without this, every jldoctest fails with UndefVarError.
DocMeta.setdocmeta!(Project3, :DocTestSetup, :(using Project3); recursive = true)

makedocs(
    sitename = "Project3.jl",
    modules  = [Project3],
    # Write design.html rather than design/index.html, so that the built pages
    # can be opened from the file system. With the pretty form the links
    # between pages point at directories, which a browser cannot follow over
    # file://, and reading the documentation locally would need a web server.
    format   = Documenter.HTML(prettyurls = false),
    pages = [
        "Home"           => "index.md",
        "Project design" => "design.md",
        "Reference manual"  => "manual.md",
    ],
    # Fail the build if an exported function has no docstring.
    checkdocs = :exports,
)

# Deployment is handled by the GitHub Actions workflow in .github/workflows/docs.yml,
# which uploads docs/build directly to GitHub Pages.
# Pin Mermaid to 11.16.1 because Mermaid 11.17.x is
# incompatible with Documenter's RequireJS environment.
build_dir = joinpath(@__DIR__, "build")
mermaid_latest = "https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs"
mermaid_pinned = "https://cdn.jsdelivr.net/npm/mermaid@11.16.1/dist/mermaid.esm.min.mjs"

for (root, _, files) in walkdir(build_dir)
    for file in files
        endswith(file, ".html") || continue

        path = joinpath(root, file)
        content = read(path, String)

        if occursin(mermaid_latest, content)
            content = replace(content, mermaid_latest => mermaid_pinned)
            write(path, content)
        end
    end
end