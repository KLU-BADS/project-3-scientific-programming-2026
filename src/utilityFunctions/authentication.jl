"""The authenticated user for the current command-line application session."""
const SESSION_COOKIE = Ref{Union{AuthenticatedUser, Nothing}}(nothing)

_normalize_user_name(user_name::AbstractString) = strip(String(user_name))

function _parse_role(role::UserRole)
    return role
end

function _parse_role(role::AbstractString)
    normalized_role = replace(uppercase(strip(role)), '-' => '_', ' ' => '_')
    normalized_role == "ADMIN" && return ADMIN
    normalized_role == "VEHICLE_OPERATOR" && return VEHICLE_OPERATOR
    normalized_role == "COMPANY" && return COMPANY
    throw(ArgumentError("role must be ADMIN, VEHICLE_OPERATOR, or COMPANY."))
end

function _authenticated_user(document)
    vehicle_id = get(document, "vehicleId", nothing)
    return AuthenticatedUser(
        string(document["_id"]),
        String(document["userName"]),
        _parse_role(String(document["role"])),
        isnothing(vehicle_id) ? nothing : String(vehicle_id),
    )
end

"""
    sign_up(user_name, password, role; vehicle_id=nothing) -> AuthenticatedUser

Create a user in MongoDB's `users` collection. Only `VEHICLE_OPERATOR` users
may provide a vehicle ID. The returned value intentionally excludes the stored
password; use `login` to create a session.
"""
function sign_up(
    user_name::AbstractString,
    password::AbstractString,
    role::Union{UserRole, AbstractString};
    vehicle_id::Union{AbstractString, Nothing}=nothing,
)
    normalized_user_name = _normalize_user_name(user_name)
    isempty(normalized_user_name) && throw(ArgumentError("user name cannot be empty."))
    isempty(password) && throw(ArgumentError("password cannot be empty."))
    parsed_role = _parse_role(role)
    normalized_vehicle_id = isnothing(vehicle_id) ? nothing : strip(String(vehicle_id))

    if parsed_role == VEHICLE_OPERATOR
        (isnothing(normalized_vehicle_id) || isempty(normalized_vehicle_id)) &&
            throw(ArgumentError("vehicle_id is required for VEHICLE_OPERATOR."))
    elseif !isnothing(normalized_vehicle_id)
        throw(ArgumentError("vehicle_id is only allowed for VEHICLE_OPERATOR."))
    end

    !isempty(getByKeyValue("users", "userName", normalized_user_name; pageSize=1)) &&
        throw(ArgumentError("a user with this user name already exists."))

    document = Dict{String, Any}(
        "userName" => normalized_user_name,
        "password" => String(password),
        "role" => string(parsed_role),
    )
    !isnothing(normalized_vehicle_id) && (document["vehicleId"] = normalized_vehicle_id)
    user_id = string(addRecord("users", document))
    user = AuthenticatedUser(user_id, normalized_user_name, parsed_role, normalized_vehicle_id)
    return user
end

"""
    login(user_name, password) -> Union{AuthenticatedUser, Nothing}

Validate a user's credentials from MongoDB and create an in-memory session.
"""
function login(user_name::AbstractString, password::AbstractString)
    normalized_user_name = _normalize_user_name(user_name)
    isempty(normalized_user_name) && throw(ArgumentError("user name cannot be empty."))
    isempty(password) && throw(ArgumentError("password cannot be empty."))

    matches = getByKeyValue("users", "userName", normalized_user_name; pageSize=1)
    isempty(matches) && return nothing
    user_document = only(matches)
    String(password) == String(user_document["password"]) || return nothing

    user = _authenticated_user(user_document)
    SESSION_COOKIE[] = user
    return user
end

"""Delete the current in-memory session cookie and return `nothing`."""
function logout!()
    SESSION_COOKIE[] = nothing
    return nothing
end

"""Return the authenticated user for this process, or `nothing` when logged out."""
current_session() = SESSION_COOKIE[]

"""
    authenticate(user_name, password; find_user_by_email, verify_password)

Compatibility helper for repository-injected authentication. New application
code should call `login` to authenticate against MongoDB.
"""
function authenticate(
    user_name::AbstractString,
    password::AbstractString;
    find_user_by_email::Function,
    verify_password::Function,
)
    normalized_user_name = _normalize_user_name(user_name)
    isempty(normalized_user_name) && throw(ArgumentError("user name cannot be empty."))
    isempty(password) && throw(ArgumentError("password cannot be empty."))

    user = find_user_by_email(normalized_user_name)
    isnothing(user) && return nothing
    verify_password(password, user) || return nothing
    user isa AuthenticatedUser || throw(ArgumentError("find_user_by_email must return AuthenticatedUser or nothing."))
    return user
end

function _prompt(input::IO, output::IO, label::AbstractString)
    print(output, label)
    flush(output)
    eof(input) && return nothing
    return strip(readline(input))
end

"""Run the sign-up, login, and logout menu used by `julia main.jl`."""
function run_authentication_cli(; input::IO=stdin, output::IO=stdout)
    while true
        println(output, "\n1. Sign up\n2. Log in\n3. Log out\n4. Exit")
        choice = _prompt(input, output, "Choose an option: ")
        isnothing(choice) && return nothing

        try
            if choice == "1"
                user_name = _prompt(input, output, "User name: ")
                password = _prompt(input, output, "Password: ")
                role = _prompt(input, output, "Role (ADMIN, VEHICLE_OPERATOR, COMPANY): ")
                any(isnothing, (user_name, password, role)) && return nothing
                parsed_role = _parse_role(role)
                vehicle_id = parsed_role == VEHICLE_OPERATOR ?
                    _prompt(input, output, "Vehicle ID: ") : nothing
                user = sign_up(user_name, password, parsed_role; vehicle_id=vehicle_id)
                println(output, "Sign-up successful. User ID: $(user.id)")
            elseif choice == "2"
                user_name = _prompt(input, output, "User name: ")
                password = _prompt(input, output, "Password: ")
                any(isnothing, (user_name, password)) && return nothing
                user = login(user_name, password)
                if isnothing(user)
                    println(output, "Invalid user name or password.")
                else
                    println(output, "Logged in as $(user.user_name). User ID: $(user.id)")
                    featureFunctionaility(user; input=input, output=output)
                    return nothing
                end
            elseif choice == "3"
                logout!()
                println(output, "Logged out.")
            elseif choice == "4"
                return nothing
            else
                println(output, "Choose 1, 2, 3, or 4.")
            end
        catch error
            println(output, "Authentication error: $(sprint(showerror, error))")
        end
    end
end

# Camel-case aliases match the names used in the initial specification.
signUp(args...; kwargs...) = sign_up(args...; kwargs...)
logIn(args...; kwargs...) = login(args...; kwargs...)
logOut() = logout!()
