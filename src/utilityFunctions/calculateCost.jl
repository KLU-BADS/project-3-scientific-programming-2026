function calculateCost(
    vehicleCapacity::Integer,
    consumedCapacityA::Integer,
    distanceA::Integer,
    distanceB::Integer,
    sharedDistance::Integer,
    price_per_km_cents::Integer=200,
    currency::AbstractString="EUR"
)
    remainingCapacity = vehicleCapacity - consumedCapacityA #Sale de la DB
    price_in_eur = price_per_km_cents / 100

    totalCost = price_in_eur * distanceA * vehicleCapacity

    if sharedDistance == 0  #Realmente no es necesario tener esto
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


vehicleCapacity = 33 #TEST
consumedCapacityA = 15 #TEST
distanceA = 100 #TEST
distanceB = 80 #TEST
sharedDistance = 40 #TEST


totalCost, costCompanyA, costCompanyB = calculateCost(vehicleCapacity, consumedCapacityA, distanceA, distanceB, sharedDistance)

println("Price for only company A: ", totalCost)
println("Shared price for company A: ", costCompanyA)
println("Shared price for company B: ", costCompanyB)
