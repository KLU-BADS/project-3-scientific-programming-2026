const GUEST_MENU = [
    :login => "Log in",
    :signup => "Sign up",
    :exit => "Exit",
]

const CLIENT_MENU = [
    :book_vehicle => "Book loading vehicle",
    :list_vehicle => "List loading vehicle with remaining capacity",
    :previous_bookings => "View previous bookings",
    :cancel_booking => "Cancel booking",
    :logout => "Log out",
]

const ADMIN_MENU = [CLIENT_MENU[1:end-1]; :show_bookings => "Show bookings"; CLIENT_MENU[end]]

# One-level RBAC: each role maps to the feature actions it is permitted to use.
const ROLE_FEATURE_MENUS = Dict{UserRole, Vector{Pair{Symbol, String}}}(
    ADMIN => [
        :add_vehicle => "Add vehicle",
        :book_vehicle => "Book loading vehicle",
        :list_vehicle => "List loading vehicle with remaining capacity",
        :previous_bookings => "View previous bookings",
        :cancel_booking => "Cancel booking",
    ],
    VEHICLE_OPERATOR => [
        :vehicle_bookings => "View bookings for my vehicle",
    ],
    COMPANY => [
        :book_vehicle => "Book loading vehicle",
        :list_vehicle => "List loading vehicle with remaining capacity",
        :previous_bookings => "View previous bookings",
        :cancel_booking => "Cancel booking",
    ],
)

const SESSION_ACTIONS = [
    :logout => "Log out",
    :exit => "Exit",
]

"Feature placeholder: implement vehicle booking here." 
_book_loading_vehicle(::AuthenticatedUser, output::IO) = println(output, "Book loading vehicle: not implemented yet.")

"Feature placeholder: implement vehicle creation here." 
_add_vehicle(::AuthenticatedUser, output::IO) = println(output, "Add vehicle: not implemented yet.")

"Feature placeholder: implement remaining-capacity listings here." 
_list_loading_vehicle(::AuthenticatedUser, output::IO) = println(output, "List loading vehicle: not implemented yet.")

"Feature placeholder: implement company booking history here." 
_view_previous_bookings(::AuthenticatedUser, output::IO) = println(output, "View previous bookings: not implemented yet.")

"Feature placeholder: implement booking cancellation here." 
_cancel_booking(::AuthenticatedUser, output::IO) = println(output, "Cancel booking: not implemented yet.")

"Feature placeholder: restrict this query to the signed-in operator's vehicle." 
function _view_vehicle_bookings(user::AuthenticatedUser, output::IO)
    println(output, "Bookings for vehicle $(user.vehicle_id): not implemented yet.")
end

function _run_feature(action::Symbol, user::AuthenticatedUser, output::IO)
    action === :add_vehicle && return _add_vehicle(user, output)
    action === :book_vehicle && return _book_loading_vehicle(user, output)
    action === :list_vehicle && return _list_loading_vehicle(user, output)
    action === :previous_bookings && return _view_previous_bookings(user, output)
    action === :cancel_booking && return _cancel_booking(user, output)
    action === :vehicle_bookings && return _view_vehicle_bookings(user, output)
    error("Unknown feature action: $action")
end

"""
    featureFunctionaility(user; input=stdin, output=stdout)

Show the post-login role-based menu. The spelling follows the requested
function name. Select `Exit` to leave the application or `Log out` to clear
the in-memory session.
"""
function featureFunctionaility(
    user::AuthenticatedUser;
    input::IO=stdin,
    output::IO=stdout,
)
    options = [ROLE_FEATURE_MENUS[user.role]; SESSION_ACTIONS]
    while true
        println(output, "\nCollaborative Loading — $(user.role)")
        for (index, (_, label)) in enumerate(options)
            println(output, "$(index). $(label)")
        end
        print(output, "Select an option: ")
        flush(output)
        eof(input) && return :exit
        choice = tryparse(Int, strip(readline(input)))
        if isnothing(choice) || !(1 <= choice <= length(options))
            println(output, "Select a valid menu number.")
            continue
        end

        action = options[choice].first
        action === :exit && return :exit
        if action === :logout
            logout!()
            println(output, "Logged out.")
            return :logout
        end
        _run_feature(action, user, output)
    end
end

# Correctly-spelled alias for callers that prefer it.
featureFunctionality(args...; kwargs...) = featureFunctionaility(args...; kwargs...)

"""
    showMenu(; role=:guest, input=stdin, output=stdout) -> Symbol

Render the appropriate CLI menu and return a validated action. The caller owns
the application loop and routes the returned action to a use case.
"""
function showMenu(; role::Symbol=:guest, input::IO=stdin, output::IO=stdout)
    options = role === :guest ? GUEST_MENU : role === :admin ? ADMIN_MENU : role === :client ? CLIENT_MENU :
        throw(ArgumentError("role must be :guest, :client, or :admin."))
    println(output, "\nCollaborative Loading")
    for (index, (_, label)) in enumerate(options)
        println(output, "$(index). $(label)")
    end
    print(output, "Select an option: ")
    flush(output)
    choice = tryparse(Int, strip(readline(input)))
    (isnothing(choice) || !(1 <= choice <= length(options))) &&
        throw(ArgumentError("Select a valid menu number."))
    return options[choice].first
end
