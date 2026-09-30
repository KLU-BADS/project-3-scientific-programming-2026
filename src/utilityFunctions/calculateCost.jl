"""Return solo price, or both parties' prices for a shared trip, in cents."""
function calculateCost(vehicleCapacity::Integer, consumedCapacityA::Integer,
    distanceA::Integer, distanceB::Integer, sharedDistance::Integer,
    price_per_km_cents::Integer=200, currency::AbstractString="EUR")
    vehicleCapacity > 0 || throw(ArgumentError("vehicle capacity must be positive"))
    0 <= consumedCapacityA <= vehicleCapacity || throw(ArgumentError("invalid used capacity"))
    0 <= sharedDistance <= min(distanceA, distanceB) || throw(ArgumentError("invalid shared distance"))
    solo = round(Int, price_per_km_cents * distanceA * vehicleCapacity)
    sharedDistance == 0 && return (solo, solo)
    remaining = vehicleCapacity - consumedCapacityA
    common = price_per_km_cents * sharedDistance * vehicleCapacity
    a = price_per_km_cents * (distanceA-sharedDistance) * vehicleCapacity + common*consumedCapacityA/vehicleCapacity
    b = price_per_km_cents * (distanceB-sharedDistance) * vehicleCapacity + common*remaining/vehicleCapacity
    return (solo, round(Int, a), round(Int, b))
end

function calculateCost(distance_km::Real, pallets::Integer; base_price_cents::Integer=100,
    price_per_km_cents::Integer=10, price_per_pallet_cents::Integer=5)
    pallets > 0 || throw(ArgumentError("pallets must be positive"))
    distance_km >= 0 || throw(ArgumentError("distance cannot be negative"))
    cents = base_price_cents + round(Int, distance_km * price_per_km_cents) + pallets * price_per_pallet_cents
    return CostQuote(cents, "EUR", Float64(distance_km), Int(pallets))
end
