"""
    addBooking(booking; save_booking!) -> booking_id

Validate a booking and delegate persistence to `save_booking!`. The callback
receives the validated `BookingRequest` and must return the new record ID. This
keeps MongoDB and business rules independent.
"""
function addBooking(booking::BookingRequest; save_booking!::Function)
    _validate_booking(booking)
    booking_id = save_booking!(booking)
    isnothing(booking_id) && throw(ArgumentError("save_booking! must return the new booking ID."))
    return booking_id
end
