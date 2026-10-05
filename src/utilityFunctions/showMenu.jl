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
        :show_bookings => "Show bookings",
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

_money(cents) = "€$(round(Float64(cents)/100; digits=2))"
_party(d) = d["company_a"]
_active(d) = get(d, "status", "IN_PROGRESS") == "IN_PROGRESS" && isnothing(get(d, "cancelled_at", nothing))

function _prompt_value(input, output, label)
    value = _prompt(input, output, label)
    (isnothing(value) || isempty(value)) && throw(ArgumentError("A value is required."))
    return value
end
function _datehour(input, output, label)
    while true
        raw = _prompt_value(input, output, label)
        try
            m = match(r"^(\d{2}-\d{2}-\d{4})[, ]+([0-2]?\d)(?:-([0-2]?\d))?$", raw)
            isnothing(m) && error("Use dd-mm-yyyy, HH or dd-mm-yyyy, HH-HH")
            date = Date(m[1], dateformat"dd-mm-yyyy")
            hour1 = parse(Int, m[2]); hour2 = isnothing(m[3]) ? hour1 : parse(Int, m[3])
            0 <= hour1 <= 23 && 0 <= hour2 <= 23 || error("Hours must be from 00 to 23")
            start = DateTime(date) + Hour(hour1); stop = DateTime(date) + Hour(hour2)
            stop < start && (stop += Day(1))
            return start, stop
        catch e
            println(output, "Invalid date/time: $(sprint(showerror, e))")
        end
    end
end
function _save_invoice!(company, amount, vehicle, origin, destination; booking_id=nothing)
    addMethod("invoices", Invoice(amount, "EUR", "Vehicle operator", origin, destination,
        vehicle, Date(now()), now(), company, booking_id))
end
function _listing_from_booking(d)
    a = _party(d)
    return VehicleListing(String(a["vehicle_id"]), String(d["id"]), String(a["company_id"]),
        Int(get(d, "remaining_capacity", 0)), Int(get(d, "vehicle_capacity", 30)), String(a["destination"]),
        String(get(a, "pickup_location", "Port")), DateTime(a["pickup_start"]), DateTime(a["pickup_end"]),
        DateTime(a["delivery_start"]), DateTime(a["delivery_end"]))
end

function _book_loading_vehicle(user::AuthenticatedUser, output::IO; input::IO=stdin)
    pallets = parse(Int, _prompt_value(input, output, "Pallets required: "))
    destination = _prompt_value(input, output, "Destination: ")
    goods = _prompt_value(input, output, "Type of goods: ")
    ps, pe = _datehour(input, output, "Pickup range (dd-mm-yyyy, HH-HH): ")
    ds, de = _datehour(input, output, "Delivery range (dd-mm-yyyy, HH-HH): ")
    req = BookingRequest(user.id, pallets, "Port", destination, goods, ps, pe, ds, de, false)
    _validate_booking(req)
    vehicles = filter(getAllListing("vehicles")) do v
        vid = string(get(v, "vehicle_id", get(v, "id", "")))
        !any(b -> begin
            _active(b) || return false
            a = get(b, "company_a", Dict())
            string(get(a, "vehicle_id", "")) == vid &&
                _windows_overlap(DateTime(a["pickup_start"]), DateTime(a["pickup_end"]), ps, pe)
        end, getAllListing("bookings"))
    end
    isempty(vehicles) && (println(output, "No vehicles are registered yet."); return)
    km = try
        fetchDistance("Port", destination; provider=orsDistanceProvider)
    catch error
        println(output, "Could not calculate a route: $(sprint(showerror, error))")
        println(output, "Check ORS_API_KEY configuration and the destination, then try again.")
        return
    end
    q = calculateCost(km, pallets)
    println(output, "\nAvailable new-vehicle quote: $(_money(q.amount_cents)); estimated distance $(round(km; digits=1)) km.")
    listings = getAllListing("listings")
    feasible = []
    for l in listings
        get(l, "listed_by_company_id", "") == user.id && continue
        bid = String(get(l, "booking_id", "")); b = getOneByParameter("bookings", "id", bid)
        (isnothing(b) || !_active(b) || !isnothing(get(b, "company_b", nothing))) && continue
        Int(get(l, "remaining_capacity", 0)) < pallets && continue
        listing = try _listing_from_booking(Dict("id"=>bid, "company_a"=>b["company_a"], "remaining_capacity"=>l["remaining_capacity"], "vehicle_capacity"=>l["vehicle_capacity"])) catch; continue end
        f = try
            checkFeasibilityToAllowCompanyBToBookVehicle(listing, req; distance_provider=orsDistanceProvider)
        catch
            continue
        end
        f.allowed && push!(feasible, (l,b,f))
    end
    for (i,(l,b,f)) in enumerate(feasible)
        println(output, "Shared option $(i): booking $(b["id"]), vehicle $(l["vehicle_id"]), $(l["remaining_capacity"]) pallets left, added route ~$(round(f.additional_distance_km; digits=1)) km.")
    end
    println(output, "0. Book a new vehicle")
    shared_quotes = Dict{Int, NamedTuple}()
    for (index, (listing_record, booking_record, _)) in enumerate(feasible)
        company_a = booking_record["company_a"]
        origin = String(get(company_a, "pickup_location", "Port"))
        try
            company_a_route = _orsRoute([origin, String(company_a["destination"])])
            shared_route = _orsRoute([origin, destination, String(company_a["destination"])])
            common_distance_km = min(company_a_route.distance_km, shared_route.distance_km)
            _, company_a_shared_cents, company_b_shared_cents = calculateCost(
                Int(get(listing_record, "vehicle_capacity", 30)),
                Int(company_a["pallets_used"]), pallets,
                common_distance_km, shared_route.distance_km,
                common_distance_km,
            )
            shared_quotes[index] = (
                company_a_price_cents=company_a_shared_cents,
                company_b_price_cents=company_b_shared_cents,
            )
            println(output, "Shared option $(index) quote: you pay $(_money(company_b_shared_cents)); Company A pays $(_money(company_a_shared_cents)).")
        catch error
            println(output, "Shared option $(index) price unavailable: $(sprint(showerror, error))")
        end
    end
    choice = tryparse(Int, something(_prompt(input, output, "Choose shared option number or 0: "), "0"))
    if !isnothing(choice) && 1 <= choice <= length(feasible)
        l,b,_ = feasible[choice]
        a = b["company_a"]
        shared_quote = get(shared_quotes, choice, nothing)
        if isnothing(shared_quote)
            println(output, "Could not confirm this shared booking because its route price is unavailable.")
            return
        end
        company_a_shared_price = shared_quote.company_a_price_cents
        shared_price = shared_quote.company_b_price_cents
        party = Dict("company_id"=>user.id,"vehicle_id"=>String(l["vehicle_id"]),"pickup_location"=>"Port",
            "pickup_start"=>string(ps),"pickup_end"=>string(pe),"delivery_start"=>string(ds),"delivery_end"=>string(de),
            "pallets_used"=>pallets,"payable_price_cents"=>shared_price,"destination"=>destination,"type_of_good"=>goods)
        b["company_b"] = party
        a["payable_price_cents"] = company_a_shared_price
        # This booking allows only one additional company, so consume its listing.
        filter!(listing_record -> get(listing_record, "booking_id", "") != b["id"], database["listings"])
        filter!(invoice -> begin
            same_booking = string(get(invoice, "booking_id", "")) == string(b["id"])
            legacy_invoice = isnothing(get(invoice, "booking_id", nothing)) &&
                get(invoice, "invoice_for_company_id", "") == a["company_id"] &&
                get(invoice, "vehicle_id", "") == a["vehicle_id"] &&
                get(invoice, "destination", "") == a["destination"]
            !(same_booking || legacy_invoice)
        end, database["invoices"])
        _save_invoice!(String(a["company_id"]), company_a_shared_price, String(a["vehicle_id"]),
            String(get(a, "pickup_location", "Port")), String(a["destination"]); booking_id=String(b["id"]))
        _save_invoice!(user.id, shared_price, String(l["vehicle_id"]), "Port", destination; booking_id=String(b["id"]))
        save_database(); println(output, "Shared booking confirmed. Booking ID $(b["id"]); your charge $(_money(shared_price)).")
        return
    end
    isempty(vehicles) && return
    println(output, "Vehicles:")
    for (i,v) in enumerate(vehicles); println(output, "$(i). $(get(v,"vehicle_name",get(v,"name","Vehicle"))) ($(get(v,"vehicle_capacity",30)) pallets)"); end
    vi = tryparse(Int, something(_prompt(input, output, "Choose vehicle: "), ""))
    (isnothing(vi) || !(1 <= vi <= length(vehicles))) && (println(output,"Invalid vehicle selection."); return)
    vehicle=vehicles[vi]; cap=Int(get(vehicle,"vehicle_capacity",30)); pallets <= cap || (println(output,"That vehicle lacks capacity."); return)
    price = q.amount_cents
    party=BookingParty(user.id,string(get(vehicle,"vehicle_id",get(vehicle,"id",""))),ps,pe,ds,de,pallets,price,destination,goods)
    bdoc=addMethod("bookings",Booking("",now(),nothing,user.id,nothing,party,nothing,IN_PROGRESS))
    if pallets < cap
        addMethod("listings",VehicleListing(party.vehicle_id,String(bdoc["id"]),user.id,cap-pallets,cap,destination,"Port",ps,pe,ds,de))
    end
    _save_invoice!(user.id,price,party.vehicle_id,"Port",destination; booking_id=String(bdoc["id"]))
    println(output,"Booking confirmed. ID $(bdoc["id"]); charge $(_money(price)); expected delivery by $(de).")
end

function _add_vehicle(::AuthenticatedUser, output::IO; input::IO=stdin)
    name = _prompt_value(input, output, "Vehicle name: ")
    capacity_raw = _prompt(input, output, "Capacity in pallets (default 30): ")
    capacity = isnothing(capacity_raw) || isempty(capacity_raw) ? 30 : parse(Int, capacity_raw)
    try
        v = addVehicle(name, capacity)
        println(output,"Vehicle added with ID $(v["vehicle_id"]) and capacity $capacity.")
    catch error
        println(output, "Could not add vehicle: $(sprint(showerror, error))")
    end
end

function _list_loading_vehicle(user::AuthenticatedUser, output::IO)
    records=listVehicleWithRemainingCapacity(exclude_company_id=user.id); shown=0
    for l in records
        b=getOneByParameter("bookings","id",get(l,"booking_id",""))
        (isnothing(b) || !_active(b) || !isnothing(get(b,"company_b",nothing)) || String(get(l,"listed_by_company_id",""))==user.id) && continue
        println(output,"Booking $(b["id"]): vehicle $(l["vehicle_id"]), $(l["remaining_capacity"]) pallets remaining, destination $(l["destination"]), pickup $(l["pickup_start"])–$(l["pickup_end"])"); shown+=1
    end
    shown==0 && println(output,"No shareable vehicle capacity is currently available.")
end

function _view_previous_bookings(user::AuthenticatedUser, output::IO)
    rows=filter(b -> get(b,"created_by","")==user.id || get(get(b,"company_a",Dict()),"company_id","")==user.id || get(get(b,"company_b",nothing) isa AbstractDict ? b["company_b"] : Dict(),"company_id","")==user.id,getAllListing("bookings"))
    isempty(rows) && println(output,"No previous bookings.")
    for b in rows; a=b["company_a"]; println(output,"Booking $(b["id"]) [$(get(b,"status","IN_PROGRESS"))] vehicle $(a["vehicle_id"]), $(a["destination"]), $(a["pallets_used"]) pallets" , isnothing(get(b,"company_b",nothing)) ? "" : " (shared)"); end
end

function _cancel_booking(user::AuthenticatedUser, output::IO; input::IO=stdin)
    candidates=filter(b -> string(get(b,"created_by",""))==user.id && _active(b) && isnothing(get(b,"company_b",nothing)),getAllListing("bookings"))
    isempty(candidates) && (println(output,"No cancellable solo bookings."); return)
    for b in candidates; println(output,"$(b["id"]). $(b["company_a"]["destination"]) — $(b["company_a"]["vehicle_id"])"); end
    id=_prompt_value(input,output,"Booking ID to cancel: "); b=getOneByParameter("bookings","id",id)
    (isnothing(b) || !(b in candidates)) && (println(output,"Booking not found or cannot be cancelled."); return)
    cancelBooking(id, user.id) || (println(output, "Booking could not be cancelled."); return)
    println(output,"Booking cancelled.")
end

function _view_vehicle_bookings(user::AuthenticatedUser, output::IO)
    isnothing(user.vehicle_id) && (println(output, "Your account has no assigned vehicle. Contact an administrator."); return)
    rows=filter(b -> begin
        a=get(b,"company_a",Dict()); c=get(b,"company_b",nothing)
        get(a,"vehicle_id","")==user.vehicle_id || (c isa AbstractDict && get(c,"vehicle_id","")==user.vehicle_id)
    end,getAllListing("bookings"))
    isempty(rows) && println(output,"No bookings assigned to your vehicle.")
    for b in rows
        a=b["company_a"]
        println(output,"Booking $(b["id"]) [$(get(b,"status","IN_PROGRESS"))], $(a["destination"]), $(a["pallets_used"]) pallets" , isnothing(get(b,"company_b",nothing)) ? "" : " + shared shipment")
    end
end

function _run_feature(action::Symbol, user::AuthenticatedUser, output::IO; input::IO=stdin)
    action === :add_vehicle && return _add_vehicle(user, output; input=input)
    action === :show_bookings && return _show_all_bookings(output)
    action === :book_vehicle && return _book_loading_vehicle(user, output; input=input)
    action === :list_vehicle && return _list_loading_vehicle(user, output)
    action === :previous_bookings && return _view_previous_bookings(user, output)
    action === :cancel_booking && return _cancel_booking(user, output; input=input)
    action === :vehicle_bookings && return _view_vehicle_bookings(user, output)
    error("Unknown feature action: $action")
end

function _show_all_bookings(output::IO)
    rows=getAllListing("bookings")
    isempty(rows) && println(output,"No bookings recorded.")
    for b in rows
        a=get(b,"company_a",Dict())
        println(output,"Booking $(get(b,"id","?")) [$(get(b,"status","IN_PROGRESS"))], company $(get(a,"company_id","?")), vehicle $(get(a,"vehicle_id","?")), destination $(get(a,"destination","?"))")
    end
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
        try
            _run_feature(action, user, output; input=input)
        catch error
            println(output, "Action failed: $(sprint(showerror, error))")
        end
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
