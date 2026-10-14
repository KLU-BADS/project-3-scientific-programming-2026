using Test

# This test file is intended to sit beside fetchDistance.jl.
include(joinpath(@__DIR__, "fetchDistance.jl"))

@testset "fetchDistance utilities" begin
    @testset "geocodeAddress input validation" begin
        # Empty addresses must be rejected before any API request is made.
        @test_throws ArgumentError geocodeAddress("")
        @test_throws ArgumentError geocodeAddress("   ")
    end

    @testset "_orsRoute input validation" begin
        # A route needs at least two locations; this check happens before networking.
        @test_throws ArgumentError _orsRoute(["Hachmannplatz 16, 20099 Hamburg, Germany"])

        # Empty locations must be rejected before attempting to geocode them.
        @test_throws ArgumentError _orsRoute(["", "Flughafenstraße 1-3, 22335 Hamburg, Germany"])
    end

    @testset "fetchDistance successful provider call" begin
        test_provider = function (origin, destination)
            @test origin == "Hachmannplatz 16, 20099 Hamburg, Germany"
            @test destination == "Flughafenstraße 1-3, 22335 Hamburg, Germany"
            return 287.7
        end

        distance = fetchDistance(
            "Hachmannplatz 16, 20099 Hamburg, Germany",
            "Flughafenstraße 1-3, 22335 Hamburg, Germany";
            provider = test_provider
        )

        @test distance == 287.7
        @test distance isa Float64
    end

    @testset "fetchDistance input validation" begin
        test_provider = (origin, destination) -> 10.0

        @test_throws ArgumentError fetchDistance(
            "", "Flughafenstraße 1-3, 22335 Hamburg, Germany"; provider = test_provider
        )
        @test_throws ArgumentError fetchDistance(
            "Hachmannplatz 16, 20099 Hamburg, Germany", "   "; provider = test_provider
        )
    end

    @testset "fetchDistance rejects invalid provider results" begin
        negative_provider = (origin, destination) -> -1.0
        nan_provider = (origin, destination) -> NaN

        @test_throws ArgumentError fetchDistance(
            "Hachmannplatz 16, 20099 Hamburg, Germany", "Flughafenstraße 1-3, 22335 Hamburg, Germany"; provider = negative_provider
        )
        @test_throws ArgumentError fetchDistance(
            "Hachmannplatz 16, 20099 Hamburg, Germany", "Flughafenstraße 1-3, 22335 Hamburg, Germany"; provider = nan_provider
        )
    end
end
