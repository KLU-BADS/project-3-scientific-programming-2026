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
