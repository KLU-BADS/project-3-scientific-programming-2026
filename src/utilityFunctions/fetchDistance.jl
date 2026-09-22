"""
    fetchDistance(origin, destination; provider) -> Float64

Fetch road distance in kilometres through an injected `provider(origin,
destination)`. Keeping the routing provider outside business logic makes the
application testable and lets you swap API vendors without changing bookings.
"""
function fetchDistance(origin::AbstractString, destination::AbstractString; provider::Function)
    isempty(strip(origin)) && throw(ArgumentError("origin cannot be empty."))
    isempty(strip(destination)) && throw(ArgumentError("destination cannot be empty."))
    distance_km = Float64(provider(String(origin), String(destination)))
    isfinite(distance_km) && distance_km >= 0 ||
        throw(ArgumentError("distance provider must return a finite, non-negative kilometre value."))
    return distance_km
end
