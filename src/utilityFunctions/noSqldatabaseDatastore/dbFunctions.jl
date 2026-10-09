const _COLLECTION_NAMES = Set(("users", "vehicles", "bookings", "listings", "invoices"))

function _collection(collection_name::AbstractString)
    name = String(collection_name)
    name in _COLLECTION_NAMES || throw(ArgumentError("unknown collection: $name"))
    return get!(database, name, Any[])
end

_json_value(value::DateTime) = string(value)
_json_value(value::Date) = string(value)
_json_value(value::Enum) = string(value)
_json_value(value) = value

function _record_dictionary(record::User)
    return Dict{String, Any}(
        "id" => record.id,
        "user_name" => record.user_name,
        "password" => record.password,
        "role" => string(record.role),
        "vehicle_id" => record.vehicle_id,
    )
end

function _record_dictionary(record::Vehicle)
    return Dict{String, Any}(
        "vehicle_id" => record.vehicle_id,
        "vehicle_name" => record.vehicle_name,
        "vehicle_capacity" => record.vehicle_capacity,
    )
end

function _record_dictionary(record::BookingParty)
    return Dict{String, Any}(string(field) => _json_value(getfield(record, field)) for field in fieldnames(BookingParty))
end

function _record_dictionary(record::Booking)
    return Dict{String, Any}(
        "id" => record.id,
        "created_at" => _json_value(record.created_at),
        "cancelled_at" => _json_value(record.cancelled_at),
        "created_by" => record.created_by,
        "cancelled_by" => record.cancelled_by,
        "company_a" => _record_dictionary(record.company_a),
        "company_b" => isnothing(record.company_b) ? nothing : _record_dictionary(record.company_b),
        "status" => string(record.status),
    )
end

function _record_dictionary(record::VehicleListing)
    return Dict{String, Any}(string(field) => _json_value(getfield(record, field)) for field in fieldnames(VehicleListing))
end

function _record_dictionary(record::Invoice)
    return Dict{String, Any}(string(field) => _json_value(getfield(record, field)) for field in fieldnames(Invoice))
end

function _record_dictionary(record::AbstractDict)
    return Dict{String, Any}(string(key) => value for (key, value) in record)
end

function _next_id(records)
    ids = Int[]
    for record in records
        id = get(record, "id", get(record, "vehicle_id", nothing))
        isnothing(id) && continue
        parsed_id = tryparse(Int, string(id))
        isnothing(parsed_id) || push!(ids, parsed_id)
    end
    return string(isempty(ids) ? 1 : maximum(ids) + 1)
end

"""Return all records in a named JSON database collection."""
getAllListing(collection_name::AbstractString) = copy(_collection(collection_name))

"""Return the first record whose `key` equals `value`, or `nothing`."""
function getOneByParameter(collection_name::AbstractString, key::Union{AbstractString, Symbol}, value)
    field = string(key)
    for record in _collection(collection_name)
        stored_value = get(record, field, nothing)
        (!isnothing(stored_value) && (stored_value == value || string(stored_value) == string(value))) && return record
    end
    return nothing
end

"""Append a record to a collection, assign its ID when absent, and save it."""
function addMethod(collection_name::AbstractString, record)
    records = _collection(collection_name)
    document = _record_dictionary(record)
    id_key = collection_name == "vehicles" ? "vehicle_id" : "id"
    id = get(document, id_key, nothing)
    (isnothing(id) || isempty(string(id))) && (document[id_key] = _next_id(records))
    push!(records, document)
    save_database()
    return document
end

"""Add and persist a uniquely named vehicle. Capacity defaults to 30 pallets."""
function addVehicle(vehicle_name::AbstractString, vehicle_capacity::Integer=30)
    name = strip(vehicle_name)
    isempty(name) && throw(ArgumentError("vehicle name cannot be empty"))
    vehicle_capacity > 0 || throw(ArgumentError("vehicle capacity must be positive"))
    any(lowercase(String(get(v, "vehicle_name", get(v, "name", "")))) == lowercase(name) for v in _collection("vehicles")) &&
        throw(ArgumentError("vehicle name already exists"))
    return addMethod("vehicles", Vehicle("", name, Int(vehicle_capacity)))
end

"""Fetch a vehicle by ID, accepting IDs from both current and legacy records."""
function getVehicle(vehicle_id::AbstractString)
    index = findfirst(v -> string(get(v, "vehicle_id", get(v, "id", ""))) == String(vehicle_id), _collection("vehicles"))
    return isnothing(index) ? nothing : _collection("vehicles")[index]
end

"""Fetch a booking by its ID, or return `nothing`."""
getBooking(booking_id::AbstractString) = getOneByParameter("bookings", "id", booking_id)

"""Fetch bookings, optionally filtered by company, assigned vehicle, or status."""
function fetchBookings(; company_id=nothing, vehicle_id=nothing, status=nothing)
    return filter(_collection("bookings")) do booking
        (isnothing(status) || string(get(booking, "status", "")) == string(status)) || return false
        a = get(booking, "company_a", Dict())
        b = get(booking, "company_b", nothing)
        parties = b isa AbstractDict ? (a, b) : (a,)
        (isnothing(company_id) || any(p -> string(get(p, "company_id", "")) == string(company_id), parties)) || return false
        isnothing(vehicle_id) || any(p -> string(get(p, "vehicle_id", "")) == string(vehicle_id), parties)
    end
end

"""List live shared-capacity offers whose parent booking is still solo and active."""
function listVehicleWithRemainingCapacity(; exclude_company_id=nothing)
    return filter(_collection("listings")) do listing
        (isnothing(exclude_company_id) || string(get(listing, "listed_by_company_id", "")) != string(exclude_company_id)) || return false
        booking = getBooking(string(get(listing, "booking_id", "")))
        !isnothing(booking) && string(get(booking, "status", "IN_PROGRESS")) == "IN_PROGRESS" &&
            isnothing(get(booking, "cancelled_at", nothing)) && isnothing(get(booking, "company_b", nothing)) &&
            Int(get(listing, "remaining_capacity", 0)) > 0
    end
end

"""Cancel an owned solo booking; shared bookings are deliberately non-cancellable."""
function cancelBooking(booking_id::AbstractString, user_id::AbstractString)
    booking = getBooking(booking_id)
    isnothing(booking) && return false
    string(get(booking, "created_by", "")) == String(user_id) || return false
    string(get(booking, "status", "")) == "IN_PROGRESS" || return false
    isnothing(get(booking, "company_b", nothing)) || return false
    booking["status"] = "CANCELLED"
    booking["cancelled_at"] = string(now())
    booking["cancelled_by"] = String(user_id)
    filter!(l -> string(get(l, "booking_id", "")) != String(booking_id), _collection("listings"))
    # Keep the invoice as an audit record; refunds/credit adjustments need a payment ledger.
    save_database()
    return true
end

getByKeyValue(collection_name::AbstractString, key, value) =
    filter(record -> begin
        stored_value = get(record, string(key), nothing)
        !isnothing(stored_value) && (stored_value == value || string(stored_value) == string(value))
    end, _collection(collection_name))

addRecord(collection_name::AbstractString, record) = addMethod(collection_name, record)
getAll(collection_name::AbstractString) = getAllListing(collection_name)
