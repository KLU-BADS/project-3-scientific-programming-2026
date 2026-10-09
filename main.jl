"""
    run_app()

Start the application using its local JSON database, then run the sign-up,
login, and logout menu.
"""

# Make `julia main.jl` work from a fresh clone. Dependencies belong to this
# project, so activate it and install anything declared in Project.toml before
# loading Project3.
using Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()

using Project3

function run_app()
    try
        # Reload at runtime so the CLI always reads the current JSON file,
        # including when Julia has loaded a precompiled Project3 module.
        UtilityFunctions.load_database!()
        users = getAllListing("users")
        println("Local JSON database loaded.")
        println("Users collection is $(isempty(users) ? "empty" : "available").")
        run_authentication_cli()
    catch error
        println(stderr, "Application error: $(sprint(showerror, error))")
    end
    return nothing
end

if abspath(PROGRAM_FILE) == abspath(@__FILE__)
    run_app()
end
