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

"""Add and persist a vehicle. Capacity defaults to zero when not supplied."""
addVehicle(vehicle_name::String, vehicle_capacity::Int=0) =
    addMethod("vehicles", Vehicle("", vehicle_name, vehicle_capacity))

getByKeyValue(collection_name::AbstractString, key, value) =
    filter(record -> begin
        stored_value = get(record, string(key), nothing)
        !isnothing(stored_value) && (stored_value == value || string(stored_value) == string(value))
    end, _collection(collection_name))

addRecord(collection_name::AbstractString, record) = addMethod(collection_name, record)
getAll(collection_name::AbstractString) = getAllListing(collection_name)
