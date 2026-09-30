# """
#     fetchDistance(origin, destination; provider) -> Float64

# Fetch road distance in kilometres through an injected `provider(origin,
# destination)`. Keeping the routing provider outside business logic makes the
# application testable and lets you swap API vendors without changing bookings.
# """
# function fetchDistance(origin::AbstractString, destination::AbstractString; provider::Function)
#     isempty(strip(origin)) && throw(ArgumentError("origin cannot be empty."))
#     isempty(strip(destination)) && throw(ArgumentError("destination cannot be empty."))
#     distance_km = Float64(provider(String(origin), String(destination)))
#     isfinite(distance_km) && distance_km >= 0 ||
#         throw(ArgumentError("distance provider must return a finite, non-negative kilometre value."))
#     return distance_km
# end

using HTTP
using JSON

const ORS_GEOCODE_URL = "https://api.heigit.org/pelias/v1/search"
const ORS_DIRECTIONS_URL =
    "https://api.heigit.org/openrouteservice/v2/directions/driving-hgv"


"""
    geocodeAddress(address) -> NamedTuple

Convert a human-readable address into latitude and longitude
using the openrouteservice geocoding API.
"""
function geocodeAddress(address::AbstractString)
    isempty(strip(address)) &&
        throw(ArgumentError("address cannot be empty."))

    api_key = get(ENV, "ORS_API_KEY", "")

    isempty(api_key) &&
        throw(ArgumentError("ORS_API_KEY environment variable is not set."))

    response = HTTP.get(
    ORS_GEOCODE_URL;

    query = [
        "text" => String(address),
        "boundary.country" => "DEU",
        "focus.point.lat" => "53.5511",
        "focus.point.lon" => "9.9937"
    ],
        headers = [
            "Authorization" => api_key,
            "Accept" => "application/json"
        ]
    )

    response.status == 200 ||
    throw(ErrorException(
        "ORS routing request failed with status $(response.status): $(String(response.body))"
    ))

    data = JSON.parse(String(response.body))

    features = get(data, "features", [])

    isempty(features) &&
        throw(ArgumentError("No location found for address: $address"))

    coordinates = features[1]["geometry"]["coordinates"]

    return (
        lat = Float64(coordinates[2]),
        lng = Float64(coordinates[1])
    )
end


"""
    _orsRoute(origins, destination) -> NamedTuple

Calculate a heavy-goods-vehicle route using openrouteservice.

`origins` is a vector of human-readable addresses. The addresses are routed
in the supplied order.

Returns:
- `distance_km`
- `duration_seconds`
"""
function _orsRoute(
    locations::AbstractVector{<:AbstractString}
)
    length(locations) >= 2 ||
        throw(ArgumentError("At least two locations are required."))

    api_key = get(ENV, "ORS_API_KEY", "")

    isempty(api_key) &&
        throw(ArgumentError("ORS_API_KEY environment variable is not set."))

    coordinates = map(locations) do location
        isempty(strip(location)) &&
            throw(ArgumentError("location cannot be empty."))

        point = geocodeAddress(location)

        [
            point.lng,
            point.lat
        ]
    end

    body = JSON.json(Dict(
        "coordinates" => coordinates
    ))

    response = HTTP.post(
        ORS_DIRECTIONS_URL;
        headers = [
            "Authorization" => api_key,
            "Content-Type" => "application/json",
            "Accept" => "application/json"
        ],
        body = body
    )

    response.status == 200 ||
        throw(ErrorException(
            "ORS routing request failed with status $(response.status)."
        ))

    data = JSON.parse(String(response.body))

    routes = get(data, "routes", [])

    isempty(routes) &&
        throw(ArgumentError(
            "ORS could not find a route through the supplied locations."
        ))

    summary = routes[1]["summary"]

    distance_m = Float64(summary["distance"])
    duration_seconds = Float64(summary["duration"])

    isfinite(distance_m) && distance_m >= 0 ||
        throw(ArgumentError("ORS returned an invalid distance."))

    isfinite(duration_seconds) && duration_seconds >= 0 ||
        throw(ArgumentError("ORS returned an invalid duration."))

    return (
        distance_km = distance_m / 1000,
        duration_seconds = duration_seconds
    )
end


"""
    orsDistanceProvider(origin, destination) -> Float64

Calculate the heavy-goods-vehicle road distance in kilometres
between two addresses using openrouteservice.
"""
function orsDistanceProvider(
    origin::AbstractString,
    destination::AbstractString
)
    route = _orsRoute([origin, destination])
    return route.distance_km
end


"""
    fetchDistance(origin, destination; provider=orsDistanceProvider) -> Float64

Fetch heavy-goods-vehicle road distance in kilometres between two
locations.

The default provider uses openrouteservice.
A different provider can be injected for testing.
"""
function fetchDistance(
    origin::AbstractString,
    destination::AbstractString;
    provider::Function = orsDistanceProvider
)
    isempty(strip(origin)) &&
        throw(ArgumentError("origin cannot be empty."))

    isempty(strip(destination)) &&
        throw(ArgumentError("destination cannot be empty."))

    distance_km = Float64(
        provider(String(origin), String(destination))
    )

    isfinite(distance_km) && distance_km >= 0 ||
        throw(
            ArgumentError(
                "distance provider must return a finite, non-negative kilometre value."
            )
        )

    return distance_km
end