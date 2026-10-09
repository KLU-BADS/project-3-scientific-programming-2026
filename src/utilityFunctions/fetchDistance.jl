# =============================================================================
# openrouteservice (ORS) routing helpers
#
# Provides geocoding (address -> coordinates) and heavy-goods-vehicle (HGV)
# road-distance calculation using the openrouteservice / HeiGIT APIs.
#
# Public entry point:  fetchDistance(origin, destination; provider=...)
# =============================================================================

using HTTP   # HTTP client for calling the ORS REST endpoints
using JSON   # JSON encoding/decoding of request and response bodies

# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------

# Pelias-based geocoding endpoint: converts free-text addresses to coordinates.
const ORS_GEOCODE_URL = "https://api.heigit.org/pelias/v1/search"

# Directions endpoint using the "driving-hgv" profile, so routes respect
# truck restrictions (weight, height, road types, etc.).
const ORS_DIRECTIONS_URL =
    "https://api.heigit.org/openrouteservice/v2/directions/driving-hgv"

# Last-resort API key used only when neither the ORS_API_KEY environment
# variable nor the project's .env file provides one.
# NOTE: Hard-coding a key in source is a security risk if this file is shared
# or committed to a public repository; prefer the env variable / .env file.
const ORS_API_KEY_FALLBACK = "eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjczN2EwNTIyZjBjZDRiOTJhZWFjYjA2Njk5Y2E4NGYzIiwiaCI6Im11cm11cjY0In0="

# -----------------------------------------------------------------------------
# API key resolution
# -----------------------------------------------------------------------------

"""
    orsApiKey() -> AbstractString

Resolve the openrouteservice API key, checking sources in this order:

1. The `ORS_API_KEY` environment variable.
2. An `ORS_API_KEY=...` line in the `.env` file two directories above this file.
3. The hard-coded `ORS_API_KEY_FALLBACK` constant.
"""
function orsApiKey()
    # 1) Environment variable takes highest priority.
    env_key = strip(get(ENV, "ORS_API_KEY", ""))
    !isempty(env_key) && return env_key

    # 2) Look for a .env file at the project root (two levels up from this file).
    env_file = joinpath(@__DIR__, "..", "..", ".env")
    if isfile(env_file)
        for line in eachline(env_file)
            entry = strip(line)

            # Only consider lines that define ORS_API_KEY.
            startswith(entry, "ORS_API_KEY") || continue

            # Split into key and value on the first '=' only, so values
            # containing '=' (e.g. base64 padding) stay intact.
            pair = split(entry, '='; limit=2)
            length(pair) == 2 || continue
            value = strip(pair[2])

            # Remove surrounding double or single quotes, if present.
            if length(value) >= 2 && value[1] == '"' && value[end] == '"'
                value = value[2:end-1]
            elseif length(value) >= 2 && value[1] == '\'' && value[end] == '\''
                value = value[2:end-1]
            end

            # Return the first non-empty value found.
            !isempty(strip(value)) && return strip(value)
        end
    end

    # 3) Fall back to the built-in key.
    return ORS_API_KEY_FALLBACK
end

# -----------------------------------------------------------------------------
# Geocoding
# -----------------------------------------------------------------------------

"""
    geocodeAddress(address) -> NamedTuple

Convert a human-readable address into latitude and longitude
using the openrouteservice geocoding API.

Search is restricted to Germany (`DEU`) and biased towards Hamburg city
centre, so ambiguous addresses resolve to nearby matches first.

Returns `(lat = ..., lng = ...)` for the best-ranked match.

Throws `ArgumentError` if the address is empty, no API key is available,
or no location is found; throws `ErrorException` on a non-200 response.
"""
function geocodeAddress(address::AbstractString)
    # Reject empty / whitespace-only input before making a network call.
    isempty(strip(address)) &&
        throw(ArgumentError("address cannot be empty."))

    api_key = orsApiKey()
    isempty(api_key) &&
        throw(ArgumentError("Set the ORS_API_KEY environment variable to enable routing."))

    # Query the geocoder.
    response = HTTP.get(
    ORS_GEOCODE_URL;

    query = [
        "text" => String(address),          # the address to search for
        "boundary.country" => "DEU",        # limit results to Germany
        "focus.point.lat" => "53.5511",     # bias results towards Hamburg
        "focus.point.lon" => "9.9937"
    ],
        headers = [
            "Authorization" => api_key,
            "Accept" => "application/json"
        ]
    )

    # Any non-200 status is treated as a failure.
    # (Note: HTTP.jl by default already throws on 4xx/5xx statuses.)
    response.status == 200 ||
    throw(ErrorException(
        "ORS routing request failed with status $(response.status): $(String(response.body))"
    ))

    data = JSON.parse(String(response.body))

    # The response is GeoJSON; each match is a "feature".
    features = get(data, "features", [])

    isempty(features) &&
        throw(ArgumentError("No location found for address: $address"))

    # Take the top-ranked match. GeoJSON coordinates are ordered [lon, lat].
    coordinates = features[1]["geometry"]["coordinates"]

    return (
        lat = Float64(coordinates[2]),
        lng = Float64(coordinates[1])
    )
end

# -----------------------------------------------------------------------------
# Routing
# -----------------------------------------------------------------------------

"""
    _orsRoute(locations) -> NamedTuple

Calculate a heavy-goods-vehicle route using openrouteservice.

`locations` is a vector of at least two human-readable addresses. Each one
is geocoded, and the route visits them in the supplied order
(first = start, last = end, anything in between = waypoints).

Returns:
- `distance_km`      — total route length in kilometres
- `duration_seconds` — estimated driving time in seconds

Internal helper (leading underscore); use `fetchDistance` from outside.
"""
function _orsRoute(
    locations::AbstractVector{<:AbstractString}
)
    # A route needs at least a start and an end point.
    length(locations) >= 2 ||
        throw(ArgumentError("At least two locations are required."))

    api_key = orsApiKey()

    isempty(api_key) &&
        throw(ArgumentError("Set the ORS_API_KEY environment variable to enable routing."))

    # Geocode every address into an ORS coordinate pair [lng, lat].
    # Note: this makes one geocoding request per location.
    coordinates = map(locations) do location
        isempty(strip(location)) &&
            throw(ArgumentError("location cannot be empty."))

        point = geocodeAddress(location)

        [
            point.lng,   # ORS expects longitude first
            point.lat
        ]
    end

    # Build the JSON request body for the directions API.
    body = JSON.json(Dict(
        "coordinates" => coordinates
    ))

    # Request the HGV route.
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

    # ORS returns a list of candidate routes; the first is the recommended one.
    routes = get(data, "routes", [])

    isempty(routes) &&
        throw(ArgumentError(
            "ORS could not find a route through the supplied locations."
        ))

    # The summary holds the totals for the whole route.
    summary = routes[1]["summary"]

    distance_m = Float64(summary["distance"])        # metres
    duration_seconds = Float64(summary["duration"])  # seconds

    # Sanity-check the values before returning them.
    isfinite(distance_m) && distance_m >= 0 ||
        throw(ArgumentError("ORS returned an invalid distance."))

    isfinite(duration_seconds) && duration_seconds >= 0 ||
        throw(ArgumentError("ORS returned an invalid duration."))

    return (
        distance_km = distance_m / 1000,   # convert metres to kilometres
        duration_seconds = duration_seconds
    )
end

# -----------------------------------------------------------------------------
# Distance provider (default implementation)
# -----------------------------------------------------------------------------

"""
    orsDistanceProvider(origin, destination) -> Float64

Calculate the heavy-goods-vehicle road distance in kilometres
between two addresses using openrouteservice.

This is the default `provider` used by `fetchDistance`.
"""
function orsDistanceProvider(
    origin::AbstractString,
    destination::AbstractString
)
    # A two-point route: origin -> destination.
    route = _orsRoute([origin, destination])
    return route.distance_km
end

# -----------------------------------------------------------------------------
# Public API
# -----------------------------------------------------------------------------

"""
    fetchDistance(origin, destination; provider=orsDistanceProvider) -> Float64

Fetch heavy-goods-vehicle road distance in kilometres between two
locations.

The default provider uses openrouteservice.
A different provider can be injected for testing, e.g.

    fetchDistance("A", "B"; provider = (o, d) -> 42.0)  # returns 42.0

Any provider must accept `(origin::String, destination::String)` and return
a finite, non-negative number of kilometres.
"""
function fetchDistance(
    origin::AbstractString,
    destination::AbstractString;
    provider::Function = orsDistanceProvider
)
    # Validate inputs up front so every provider gets clean arguments.
    isempty(strip(origin)) &&
        throw(ArgumentError("origin cannot be empty."))

    isempty(strip(destination)) &&
        throw(ArgumentError("destination cannot be empty."))

    # Call the provider and normalise its result to Float64.
    distance_km = Float64(
        provider(String(origin), String(destination))
    )

    # Guard against bad provider output (NaN, Inf, negative values).
    isfinite(distance_km) && distance_km >= 0 ||
        throw(
            ArgumentError(
                "distance provider must return a finite, non-negative kilometre value."
            )
        )

    return distance_km
end