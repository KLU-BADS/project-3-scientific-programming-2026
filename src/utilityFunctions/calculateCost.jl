"""
    calculateCost(distance_km, pallets; base_price_cents=10_000,
                  price_per_km_cents=120, price_per_pallet_cents=200) -> CostQuote

Calculate a transparent price using integer cents, avoiding floating-point money
rounding errors. Replace the default rates with the pricing policy later.
"""
function calculateCost(
    distance_km::Real,
    pallets::Integer;
    base_price_cents::Integer=10_000,
    price_per_km_cents::Integer=120,
    price_per_pallet_cents::Integer=200,
    currency::AbstractString="EUR",
)
    distance_km >= 0 || throw(ArgumentError("distance_km cannot be negative."))
    pallets > 0 || throw(ArgumentError("pallets must be greater than zero."))
    all(>=(0), (base_price_cents, price_per_km_cents, price_per_pallet_cents)) ||
        throw(ArgumentError("pricing values cannot be negative."))

    distance_charge = round(Int, Float64(distance_km) * price_per_km_cents)
    total = base_price_cents + distance_charge + pallets * price_per_pallet_cents
    return CostQuote(total, String(currency), Float64(distance_km), Int(pallets))
end
