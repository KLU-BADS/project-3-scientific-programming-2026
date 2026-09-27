"""
    run_app()

Start the application using its local JSON database, then run the sign-up,
login, and logout menu.
"""

# Allow `julia main.jl` to locate this repository's Project.toml and package.
pushfirst!(LOAD_PATH, @__DIR__)

using Project3

function run_app()
    try
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
