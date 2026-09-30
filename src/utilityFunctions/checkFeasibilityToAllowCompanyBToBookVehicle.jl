# """
#     checkFeasibilityToAllowCompanyBToBookVehicle(vehicle, request;
#         distance_provider, max_detour_km=30) -> DeliveryFeasibility

# Check capacity, pickup/delivery windows, and the extra route distance needed to
# carry Company B's shipment before Company A's planned destination.
# """
# function checkFeasibilityToAllowCompanyBToBookVehicle(
#     vehicle::VehicleListing,
#     request::BookingRequest;
#     distance_provider::Function,
#     max_detour_km::Real=30,
# )
#     _validate_booking(request)
#     max_detour_km >= 0 || throw(ArgumentError("max_detour_km cannot be negative."))
#     request.pallets <= vehicle.remaining_capacity ||
#         return DeliveryFeasibility(false, "Insufficient remaining pallet capacity.", 0.0)
#     _windows_overlap(vehicle.pickup_start, vehicle.pickup_end, request.pickup_start, request.pickup_end) ||
#         return DeliveryFeasibility(false, "Pickup time windows do not overlap.", 0.0)
#     _windows_overlap(vehicle.delivery_start, vehicle.delivery_end, request.delivery_start, request.delivery_end) ||
#         return DeliveryFeasibility(false, "Delivery time windows do not overlap.", 0.0)

#     original_km = fetchDistance(vehicle.origin, vehicle.destination; provider=distance_provider)
#     shared_km = fetchDistance(vehicle.origin, request.destination; provider=distance_provider) +
#                 fetchDistance(request.destination, vehicle.destination; provider=distance_provider)
#     additional_km = max(0.0, shared_km - original_km)
#     additional_km <= max_detour_km ||
#         return DeliveryFeasibility(false, "Detour exceeds the allowed limit.", additional_km)
#     return DeliveryFeasibility(true, "Vehicle can carry this shipment.", additional_km)
# end

# # Keep the spelling from the initial specification as a compatibility alias.
# checkFeasabilityToAllowCompanyBToBookVehicle(args...; kwargs...) =
#     checkFeasibilityToAllowCompanyBToBookVehicle(args...; kwargs...)


"""
    checkFeasibilityToAllowCompanyBToBookVehicle(
        vehicle,
        request;
        distance_provider,
        route_provider,
        max_detour_km=30,
    ) -> DeliveryFeasibility

Check whether Company B can share Company A's vehicle.

The feasibility check considers:
- remaining pallet capacity,
- pickup time windows,
- actual road distance,
- additional distance caused by the shared route,
- actual road travel duration,
- Company B's delivery window,
- Company A's delivery window.

The shared route is:

    vehicle.origin → Company B destination → Company A destination
"""
function checkFeasibilityToAllowCompanyBToBookVehicle(
    vehicle::VehicleListing,
    request::BookingRequest;
    distance_provider::Function,
    route_provider::Function = _orsRoute,
    max_detour_km::Real = 30,
)
    _validate_booking(request)

    max_detour_km >= 0 ||
        throw(ArgumentError("max_detour_km cannot be negative."))

    # ---------------------------------------------------------
    # 1. Check remaining vehicle capacity
    # ---------------------------------------------------------
    request.pallets <= vehicle.remaining_capacity ||
        return DeliveryFeasibility(
            false,
            "Insufficient remaining pallet capacity.",
            0.0,
        )

    # ---------------------------------------------------------
    # 2. Check pickup time windows
    # ---------------------------------------------------------
    _windows_overlap(
        vehicle.pickup_start,
        vehicle.pickup_end,
        request.pickup_start,
        request.pickup_end,
    ) ||
        return DeliveryFeasibility(
            false,
            "Pickup time windows do not overlap.",
            0.0,
        )

    # ---------------------------------------------------------
    # 3. Calculate original Company A route
    #
    # Origin → Company A destination
    # ---------------------------------------------------------
    original_route = route_provider([
        vehicle.origin,
        vehicle.destination,
    ])

    original_km = original_route.distance_km
    original_duration_seconds = original_route.duration_seconds

    # ---------------------------------------------------------
    # 4. Calculate shared route
    #
    # Origin → Company B destination → Company A destination
    # ---------------------------------------------------------
    shared_route = route_provider([
        vehicle.origin,
        request.destination,
        vehicle.destination,
    ])

    shared_km = shared_route.distance_km

    # ---------------------------------------------------------
    # 5. Calculate additional distance
    # ---------------------------------------------------------
    additional_km = max(
        0.0,
        shared_km - original_km,
    )

    additional_km <= max_detour_km ||
        return DeliveryFeasibility(
            false,
            "Detour exceeds the allowed limit.",
            additional_km,
        )

    # ---------------------------------------------------------
    # 6. Calculate individual route legs
    #
    # Origin → Company B
    # Company B → Company A
    #
    # We need individual durations because the total shared
    # route duration alone cannot tell us whether each delivery
    # can be made within its own delivery window.
    # ---------------------------------------------------------
    origin_to_b = route_provider([
        vehicle.origin,
        request.destination,
    ])

    b_to_a = route_provider([
        request.destination,
        vehicle.destination,
    ])

    # ---------------------------------------------------------
    # 7. Determine earliest possible departure
    #
    # We use the end of the vehicle's pickup window because the
    # current data model does not contain a separate pickup
    # duration.
    # ---------------------------------------------------------
    departure_time = vehicle.pickup_end

    # The requested pickup window must also allow the vehicle
    # to be available for Company B.
    departure_time < request.pickup_start &&
        (departure_time = request.pickup_start)

    departure_time <= request.pickup_end ||
        return DeliveryFeasibility(
            false,
            "Vehicle cannot depart within Company B's pickup window.",
            additional_km,
        )

    # ---------------------------------------------------------
    # 8. Calculate Company B arrival
    # ---------------------------------------------------------
    b_travel_time = Millisecond(
        round(origin_to_b.duration_seconds * 1000)
    )

    earliest_b_arrival =
        departure_time + b_travel_time

    # If the vehicle reaches B before the delivery window,
    # it waits until the delivery window opens.
    b_arrival = max(
        earliest_b_arrival,
        request.delivery_start,
    )

    b_arrival <= request.delivery_end ||
        return DeliveryFeasibility(
            false,
            "Company B cannot be delivered within its delivery window.",
            additional_km,
        )

    # ---------------------------------------------------------
    # 9. Calculate Company A arrival
    #
    # After delivering B, the vehicle continues:
    #
    # B → Company A
    # ---------------------------------------------------------
    a_travel_time = Millisecond(
        round(b_to_a.duration_seconds * 1000)
    )

    earliest_a_arrival =
        b_arrival + a_travel_time

    # If the vehicle reaches A before A's delivery window,
    # it waits until the window opens.
    a_arrival = max(
        earliest_a_arrival,
        vehicle.delivery_start,
    )

    a_arrival <= vehicle.delivery_end ||
        return DeliveryFeasibility(
            false,
            "Company A cannot be delivered within its delivery window after serving Company B.",
            additional_km,
        )

    # ---------------------------------------------------------
    # 10. All feasibility conditions passed
    # ---------------------------------------------------------
    return DeliveryFeasibility(
        true,
        "Vehicle can carry this shipment within the required delivery windows.",
        additional_km,
    )
end


# Keep the spelling from the initial specification as a
# compatibility alias.
checkFeasabilityToAllowCompanyBToBookVehicle(args...; kwargs...) =
    checkFeasibilityToAllowCompanyBToBookVehicle(args...; kwargs...)