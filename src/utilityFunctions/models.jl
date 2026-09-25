"""Roles permitted for an application user."""
@enum UserRole::UInt8 ADMIN VEHICLE_OPERATOR COMPANY

"""Lifecycle state of a booking."""
@enum BookingStatus::UInt8 COMPLETED IN_PROGRESS CANCELLED NO_SHOW

"""
Persisted user record. `password` is stored as entered for this prototype only.
`vehicle_id` is only populated for a vehicle operator.
"""
struct User
    id::String
    user_name::String
    password::String
    role::UserRole
    vehicle_id::Union{String, Nothing}
end

"""Safe, authenticated-user view; intentionally excludes password data."""
struct AuthenticatedUser
    id::String
    user_name::String
    role::UserRole
    vehicle_id::Union{String, Nothing}
end

"""The shipment details supplied by either Company A or Company B."""
struct BookingParty
    company_id::String
    vehicle_id::String
    pickup_start::DateTime
    pickup_end::DateTime
    delivery_start::DateTime
    delivery_end::DateTime
    pallets_used::Int
    payable_price_cents::Int
    destination::String
    type_of_good::String
end

"""Persisted booking, including Company A and an optional shared-load Company B."""
struct Booking
    id::String
    created_at::DateTime
    cancelled_at::Union{DateTime, Nothing}
    created_by::String
    cancelled_by::Union{String, Nothing}
    company_a::BookingParty
    company_b::Union{BookingParty, Nothing}
    status::BookingStatus
end

"""Input used when a company requests capacity on a listed vehicle."""
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

"""A vehicle and its total pallet capacity."""
struct Vehicle
    vehicle_id::String
    vehicle_name::String
    vehicle_capacity::Int
end

"""
A bookable portion of a vehicle. The time-window fields are a denormalized
snapshot from the associated booking and are needed by the feasibility check.
"""
struct VehicleListing
    vehicle_id::String
    booking_id::String
    listed_by_company_id::String
    remaining_capacity::Int
    remaining_vehicle_capacity::Int
    destination::String
    origin::String
    pickup_start::DateTime
    pickup_end::DateTime
    delivery_start::DateTime
    delivery_end::DateTime
end

"""An invoice issued for one company."""
struct Invoice
    amount_cents::Int
    currency::String
    pay_to::String
    origin::String
    destination::String
    vehicle_id::String
    date::Date
    created_on::DateTime
    invoice_for_company_id::String
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
