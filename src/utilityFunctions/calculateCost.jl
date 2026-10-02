<<<<<<< Updated upstream
function calculateCost(
    vehicleCapacity::Integer,
    consumedCapacityA::Integer,
    distanceA::Integer,
    distanceB::Integer,
    sharedDistance::Integer,
    price_per_km_cents::Integer=200,
    currency::AbstractString="EUR"
)
    remainingCapacity = vehicleCapacity - consumedCapacityA
    price_in_eur = price_per_km_cents / 100

    totalCost = price_in_eur * distanceA * vehicleCapacity

    if sharedDistance == 0  
        return round(Int, totalCost), round(Int, totalCost)
    end

    sharedCost = price_in_eur * sharedDistance * vehicleCapacity
    privDistanceA = distanceA - sharedDistance
    privDistanceB = distanceB - sharedDistance

    sharedPriceA = sharedCost * consumedCapacityA / vehicleCapacity
    sharedPriceB = sharedCost * remainingCapacity / vehicleCapacity

    costCompanyA = price_in_eur * privDistanceA * vehicleCapacity + sharedPriceA
    costCompanyB = price_in_eur * privDistanceB * vehicleCapacity + sharedPriceB

    return round(Int, totalCost), round(Int, costCompanyA), round(Int, costCompanyB)
end


vehicleCapacity = 30 #TEST
consumedCapacityA = 15 #TEST
distanceA = 100 #TEST
distanceB = 80 #TEST
sharedDistance = 40 #TEST


totalCost, costCompanyA, costCompanyB = calculateCost(vehicleCapacity, consumedCapacityA, distanceA, distanceB, sharedDistance)

println("Price for only company A: ", totalCost)
println("Shared price for company A: ", costCompanyA)
println("Shared price for company B: ", costCompanyB)
=======
"""Return Company A's solo quote and, when shared, both parties' quotes in cents.

Distances are kilometres; the common route is split in proportion to the
pallet capacity each company uses. Company-specific route extensions are paid
by the company whose destination requires them.
"""
function calculateCost(vehicle_capacity::Integer, company_a_pallets::Integer,
    company_b_pallets::Integer, company_a_distance_km::Real,
    company_b_distance_km::Real, shared_distance_km::Real,
    price_per_km_cents::Integer=200, currency::AbstractString="EUR")
    vehicle_capacity > 0 || throw(ArgumentError("vehicle capacity must be positive"))
    0 <= company_a_pallets <= vehicle_capacity || throw(ArgumentError("invalid Company A pallet count"))
    all(isfinite, (company_a_distance_km, company_b_distance_km, shared_distance_km)) ||
        throw(ArgumentError("distances must be finite"))
    company_a_distance_km >= 0 && company_b_distance_km >= 0 && shared_distance_km >= 0 ||
        throw(ArgumentError("distances cannot be negative"))
    shared_distance_km <= min(company_a_distance_km, company_b_distance_km) ||
        throw(ArgumentError("shared distance cannot exceed either party's route"))
    price_per_km_cents >= 0 || throw(ArgumentError("price per kilometre cannot be negative"))

    solo_price_cents = round(Int, price_per_km_cents * company_a_distance_km)
    0 <= company_b_pallets <= vehicle_capacity || throw(ArgumentError("invalid Company B pallet count"))
    company_a_pallets + company_b_pallets <= vehicle_capacity ||
        throw(ArgumentError("combined pallet count exceeds vehicle capacity"))
    company_a_pallets + company_b_pallets > 0 || throw(ArgumentError("at least one company must use capacity"))
    total_pallets = company_a_pallets + company_b_pallets
    company_a_pallets == 0 && return (solo_price_cents, 0, solo_price_cents)
    company_b_pallets == 0 && return (solo_price_cents, solo_price_cents, 0)

    shared_route_cost_cents = price_per_km_cents * shared_distance_km
    company_a_total = price_per_km_cents * (company_a_distance_km - shared_distance_km) +
        shared_route_cost_cents * company_a_pallets / total_pallets
    company_b_total = price_per_km_cents * (company_b_distance_km - shared_distance_km) +
        shared_route_cost_cents * company_b_pallets / total_pallets
    return (solo_price_cents, round(Int, company_a_total), round(Int, company_b_total))
end

# Backwards-compatible form: assumes Company B uses all capacity left by A.
calculateCost(vehicle_capacity::Integer, company_a_pallets::Integer,
    company_a_distance_km::Real, company_b_distance_km::Real, shared_distance_km::Real,
    price_per_km_cents::Integer=200, currency::AbstractString="EUR") =
    calculateCost(vehicle_capacity, company_a_pallets, vehicle_capacity - company_a_pallets,
        company_a_distance_km, company_b_distance_km, shared_distance_km,
        price_per_km_cents, currency)

function calculateCost(distance_km::Real, pallets::Integer; base_price_cents::Integer=0,
    price_per_km_cents::Integer=200, price_per_pallet_cents::Integer=0)
    pallets > 0 || throw(ArgumentError("pallets must be positive"))
    distance_km >= 0 || throw(ArgumentError("distance cannot be negative"))
    cents = base_price_cents + round(Int, distance_km * price_per_km_cents) + pallets * price_per_pallet_cents
    return CostQuote(cents, "EUR", Float64(distance_km), Int(pallets))
end
>>>>>>> Stashed changes
