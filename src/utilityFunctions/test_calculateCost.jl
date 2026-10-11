using Project3: calculateCost
using Test

@testset "calculateCost: single shipment" begin
    result = calculateCost(10, 2; base_price_cents=100,
        price_per_km_cents=10, price_per_pallet_cents=5)

    @test result.amount_cents == 210
    @test result.currency == "EUR"
    @test result.distance_km == 10.0
    @test result.pallets == 2
    #ArgumentError: number of pallets 0, negative distance -1, and infinite distance Inf are invalid.
    @test_throws ArgumentError calculateCost(10, 0)
    @test_throws ArgumentError calculateCost(-1, 2)
    @test_throws ArgumentError calculateCost(Inf, 2)
end

@testset "calculateCost: shared route" begin
    # Solo cost is 10 km * 200 cents/km. Shared costs divide equally by pallets.
    @test calculateCost(10, 2, 2, 10, 8, 4) == (2000, 1600, 1200)

    @test_throws ArgumentError calculateCost(0, 1, 0, 10, 8, 4)
    @test_throws ArgumentError calculateCost(10, 8, 3, 10, 8, 4)
    @test_throws ArgumentError calculateCost(10, 0, 0, 10, 8, 4)
    @test_throws ArgumentError calculateCost(10, 2, 2, -1, 8, 0)
    @test_throws ArgumentError calculateCost(10, 2, 2, 10, 8, 9)
    @test_throws ArgumentError calculateCost(10, 2, 2, 10, 8, 4; price_per_km_cents=-1)
end
