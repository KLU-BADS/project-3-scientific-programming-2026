using JSON

const DATABASE_PATH = normpath(joinpath(@__DIR__, "..", "..", "..", "noSQLdb", "database.json"))

function _default_database()
    return Dict(
        "users" => Any[],
        "vehicles" => Any[],
        "bookings" => Any[],
        "listings" => Any[],
        "invoices" => Any[],
    )
end

database = isfile(DATABASE_PATH) ? JSON.parsefile(DATABASE_PATH) : _default_database()

function load_database!()
    global database = isfile(DATABASE_PATH) ? JSON.parsefile(DATABASE_PATH) : _default_database()
    return database
end

function save_database()
    mkpath(dirname(DATABASE_PATH))
    open(DATABASE_PATH, "w") do file
        JSON.print(file, database)
    end
    return nothing
end