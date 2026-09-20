"""
    checkFeasibilityToAllowCompanyBToBookVehicle(vehicle, request;
        distance_provider, max_detour_km=30) -> DeliveryFeasibility

Check capacity, pickup/delivery windows, and the extra route distance needed to
carry Company B's shipment before Company A's planned destination.
"""
function checkFeasibilityToAllowCompanyBToBookVehicle(
    vehicle::VehicleListing,
    request::BookingRequest;
    distance_provider::Function,
    max_detour_km::Real=30,
)
    _validate_booking(request)
    max_detour_km >= 0 || throw(ArgumentError("max_detour_km cannot be negative."))
    request.pallets <= vehicle.remaining_pallet_capacity ||
        return DeliveryFeasibility(false, "Insufficient remaining pallet capacity.", 0.0)
    _windows_overlap(vehicle.pickup_start, vehicle.pickup_end, request.pickup_start, request.pickup_end) ||
        return DeliveryFeasibility(false, "Pickup time windows do not overlap.", 0.0)
    _windows_overlap(vehicle.delivery_start, vehicle.delivery_end, request.delivery_start, request.delivery_end) ||
        return DeliveryFeasibility(false, "Delivery time windows do not overlap.", 0.0)

    original_km = fetchDistance(vehicle.origin, vehicle.destination; provider=distance_provider)
    shared_km = fetchDistance(vehicle.origin, request.destination; provider=distance_provider) +
                fetchDistance(request.destination, vehicle.destination; provider=distance_provider)
    additional_km = max(0.0, shared_km - original_km)
    additional_km <= max_detour_km ||
        return DeliveryFeasibility(false, "Detour exceeds the allowed limit.", additional_km)
    return DeliveryFeasibility(true, "Vehicle can carry this shipment.", additional_km)
end

# Keep the spelling from the initial specification as a compatibility alias.
checkFeasabilityToAllowCompanyBToBookVehicle(args...; kwargs...) =
    checkFeasibilityToAllowCompanyBToBookVehicle(args...; kwargs...)
