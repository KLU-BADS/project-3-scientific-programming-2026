"""Return Company A's solo price and both parties' shared prices, in cents."""
function calculateCost(vehicle_capacity::Integer, company_a_pallets::Integer,
    company_a_distance_km::Real, company_b_distance_km::Real,
    shared_distance_km::Real, price_per_km_cents::Integer=200,
    currency::AbstractString="EUR")
    vehicle_capacity > 0 || throw(ArgumentError("vehicle capacity must be positive"))
    0 <= company_a_pallets <= vehicle_capacity ||
        throw(ArgumentError("invalid Company A pallet count"))
    all(isfinite, (company_a_distance_km, company_b_distance_km, shared_distance_km)) ||
        throw(ArgumentError("distances must be finite"))
    company_a_distance_km >= 0 && company_b_distance_km >= 0 && shared_distance_km >= 0 ||
        throw(ArgumentError("distances cannot be negative"))
    shared_distance_km <= min(company_a_distance_km, company_b_distance_km) ||
        throw(ArgumentError("shared distance cannot exceed either party's route"))
    price_per_km_cents >= 0 || throw(ArgumentError("price per kilometre cannot be negative"))

    solo_price_cents = round(Int, company_a_distance_km * price_per_km_cents)
    shared_distance_km == 0 && return (solo_price_cents, solo_price_cents)

    company_b_pallets = vehicle_capacity - company_a_pallets
    total_pallets = company_a_pallets + company_b_pallets
    total_pallets > 0 || throw(ArgumentError("at least one company must use capacity"))
    common_route_cost_cents = shared_distance_km * price_per_km_cents
    company_a_price_cents = (company_a_distance_km - shared_distance_km) * price_per_km_cents +
        common_route_cost_cents * company_a_pallets / total_pallets
    company_b_price_cents = (company_b_distance_km - shared_distance_km) * price_per_km_cents +
        common_route_cost_cents * company_b_pallets / total_pallets
    return (solo_price_cents, round(Int, company_a_price_cents), round(Int, company_b_price_cents))
end

function calculateCost(distance_km::Real, pallets::Integer; base_price_cents::Integer=100,
    price_per_km_cents::Integer=10, price_per_pallet_cents::Integer=5)
    pallets > 0 || throw(ArgumentError("pallets must be positive"))
    isfinite(distance_km) && distance_km >= 0 ||
        throw(ArgumentError("distance must be finite and non-negative"))
    cents = base_price_cents + round(Int, distance_km * price_per_km_cents) +
        pallets * price_per_pallet_cents
    return CostQuote(cents, "EUR", Float64(distance_km), Int(pallets))
end
