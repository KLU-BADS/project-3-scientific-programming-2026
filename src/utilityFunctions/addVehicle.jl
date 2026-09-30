"""Maximum number of Euro pallets one vehicle can carry."""
const MAX_PALLET_PER_VEHICLE_CAPACITY = 30

"""
    addVehicle(vehicle_name, vehicle_capacity) -> Dict

Validate and save a new vehicle. Capacity defaults to MAX_PALLET_PER_VEHICLE_CAPACITY.
Throws ArgumentError for an empty name, a bad capacity, or a duplicate name.
"""
function addVehicle(
    vehicle_name::AbstractString,
    vehicle_capacity::Int=MAX_PALLET_PER_VEHICLE_CAPACITY,
)
    name = String(strip(vehicle_name))
    isempty(name) && throw(ArgumentError("vehicle name cannot be empty."))
    (vehicle_capacity < 1 || vehicle_capacity > MAX_PALLET_PER_VEHICLE_CAPACITY) &&
        throw(ArgumentError("capacity must be between 1 and $(MAX_PALLET_PER_VEHICLE_CAPACITY)."))
    for vehicle in getAllListing("vehicles")
        lowercase(strip(string(get(vehicle, "vehicle_name", "")))) == lowercase(name) &&
            throw(ArgumentError("a vehicle with this name already exists."))
    end
    return addMethod("vehicles", Vehicle("", name, vehicle_capacity))
end

"""Return all saved vehicles as a list of dictionaries."""
getAllVehicles() = getAllListing("vehicles")

"""Return one vehicle by its ID, or nothing if it does not exist."""
function getVehicle(vehicle_id::AbstractString)
    id = String(strip(vehicle_id))
    isempty(id) && throw(ArgumentError("vehicle ID cannot be empty."))
    return getOneByParameter("vehicles", "vehicle_id", id)
end

"""Return the vehicle of a VEHICLE_OPERATOR, or nothing if it is not found."""
function getVehicleForUser(user::AuthenticatedUser)
    user.role == VEHICLE_OPERATOR ||
        throw(ArgumentError("only a VEHICLE_OPERATOR has a vehicle."))
    isnothing(user.vehicle_id) && return nothing
    return getVehicle(user.vehicle_id)
end