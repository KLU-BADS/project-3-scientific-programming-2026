using Project3
using Test
using Dates

@testset "checkFeasibilityToAllowCompanyBToBookVehicle" begin
    pickup_start = DateTime(2026, 10, 10, 8)
    pickup_end = DateTime(2026, 10, 10, 9)
    b_delivery_start = DateTime(2026, 10, 10, 10)
    b_delivery_end = DateTime(2026, 10, 10, 12)
    a_delivery_start = DateTime(2026, 10, 10, 12)
    a_delivery_end = DateTime(2026, 10, 10, 15)

    vehicle = VehicleListing(
        "truck-1", "booking-1", "company-a", 8, 12,
        "Company A destination", "Origin",
        pickup_start, pickup_end, a_delivery_start, a_delivery_end,
    )
    request = BookingRequest(
        "company-b", 3, "Origin", "Company B destination", "Goods",
        pickup_start, pickup_end, b_delivery_start, b_delivery_end, true,
    )

    route_table = Dict(
        ("Origin", "Company A destination") => (distance_km=100.0, duration_seconds=3_600.0),
        ("Origin", "Company B destination", "Company A destination") => (distance_km=115.0, duration_seconds=5_400.0),
        ("Origin", "Company B destination") => (distance_km=60.0, duration_seconds=3_600.0),
        ("Company B destination", "Company A destination") => (distance_km=55.0, duration_seconds=3_600.0),
    )
    route_provider = locations -> route_table[Tuple(locations)]
    distance_provider = (origin, destination) -> 0.0 # Required keyword; route_provider supplies routes.

    @testset "accepts a feasible shared booking" begin
        result = checkFeasibilityToAllowCompanyBToBookVehicle(
            vehicle, request;
            distance_provider=distance_provider,
            route_provider=route_provider,
            max_detour_km=30,
        )
        @test result.allowed
        @test result.additional_distance_km == 15.0
    end

    @testset "rejects insufficient capacity" begin
        too_many_pallets = BookingRequest(
            "company-b", 9, "Origin", "Company B destination", "Goods",
            pickup_start, pickup_end, b_delivery_start, b_delivery_end, true,
        )
        result = checkFeasibilityToAllowCompanyBToBookVehicle(
            vehicle, too_many_pallets;
            distance_provider=distance_provider, route_provider=route_provider,
        )
        @test !result.allowed
        @test result.reason == "Insufficient remaining pallet capacity."
    end

    @testset "rejects non-overlapping pickup windows" begin
        no_overlap = BookingRequest(
            "company-b", 3, "Origin", "Company B destination", "Goods",
            pickup_start + Hour(2), pickup_end + Hour(2),
            b_delivery_start, b_delivery_end, true,
        )
        result = checkFeasibilityToAllowCompanyBToBookVehicle(
            vehicle, no_overlap;
            distance_provider=distance_provider, route_provider=route_provider,
        )
        @test !result.allowed
        @test result.reason == "Pickup time windows do not overlap."
    end

    @testset "rejects excessive detour" begin
        result = checkFeasibilityToAllowCompanyBToBookVehicle(
            vehicle, request;
            distance_provider=distance_provider,
            route_provider=route_provider,
            max_detour_km=10,
        )
        @test !result.allowed
        @test result.reason == "Detour exceeds the allowed limit."
        @test result.additional_distance_km == 15.0
    end

    @testset "rejects a late Company B delivery" begin
        slow_b_route = locations -> begin
            route = route_table[Tuple(locations)]
            Tuple(locations) == ("Origin", "Company B destination") ?
                (distance_km=route.distance_km, duration_seconds=20_000.0) : route
        end
        result = checkFeasibilityToAllowCompanyBToBookVehicle(
            vehicle, request;
            distance_provider=distance_provider, route_provider=slow_b_route,
        )
        @test !result.allowed
        @test result.reason == "Company B cannot be delivered within its delivery window."
    end

    @testset "rejects a late Company A delivery" begin
        slow_a_route = locations -> begin
            route = route_table[Tuple(locations)]
            Tuple(locations) == ("Company B destination", "Company A destination") ?
                (distance_km=route.distance_km, duration_seconds=20_000.0) : route
        end
        result = checkFeasibilityToAllowCompanyBToBookVehicle(
            vehicle, request;
            distance_provider=distance_provider, route_provider=slow_a_route,
        )
        @test !result.allowed
        @test result.reason == "Company A cannot be delivered within its delivery window after serving Company B."
    end

    @testset "throws for invalid inputs" begin
        @test_throws ArgumentError checkFeasibilityToAllowCompanyBToBookVehicle(
            vehicle, request;
            distance_provider=distance_provider,
            route_provider=route_provider,
            max_detour_km=-1,
        )
        invalid_request = BookingRequest(
            "company-b", 0, "Origin", "Company B destination", "Goods",
            pickup_start, pickup_end, b_delivery_start, b_delivery_end, true,
        )
        @test_throws ArgumentError checkFeasibilityToAllowCompanyBToBookVehicle(
            vehicle, invalid_request;
            distance_provider=distance_provider, route_provider=route_provider,
        )
    end
end
