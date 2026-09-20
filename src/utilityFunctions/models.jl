"Domain objects are immutable so a validated request cannot be changed accidentally."

struct AuthenticatedUser
    id::String
    company_name::String
    role::Symbol
end

struct BookingRequest
    company_id::String
    pallets::Int
    pickup_location::String
    destination::String
    goods_type::String
    pickup_start::DateTime
    pickup_end::DateTime
    delivery_start::DateTime
    delivery_end::DateTime
    share_remaining_capacity::Bool
end

struct VehicleListing
    id::String
    company_id::String
    origin::String
    destination::String
    remaining_pallet_capacity::Int
    pickup_start::DateTime
    pickup_end::DateTime
    delivery_start::DateTime
    delivery_end::DateTime
end

struct CostQuote
    amount_cents::Int
    currency::String
    distance_km::Float64
    pallets::Int
end

struct DeliveryFeasibility
    allowed::Bool
    reason::String
    additional_distance_km::Float64
end

function _validate_booking(booking::BookingRequest)
    isempty(strip(booking.company_id)) && throw(ArgumentError("company_id cannot be empty."))
    booking.pallets > 0 || throw(ArgumentError("pallets must be greater than zero."))
    all(value -> !isempty(strip(value)), (booking.pickup_location, booking.destination, booking.goods_type)) ||
        throw(ArgumentError("pickup location, destination, and goods type are required."))
    booking.pickup_start <= booking.pickup_end || throw(ArgumentError("pickup time range is invalid."))
    booking.delivery_start <= booking.delivery_end || throw(ArgumentError("delivery time range is invalid."))
    booking.pickup_end <= booking.delivery_end || throw(ArgumentError("delivery must end after pickup."))
    return booking
end

_windows_overlap(start_a, end_a, start_b, end_b) = start_a <= end_b && start_b <= end_a
