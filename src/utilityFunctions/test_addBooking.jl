using Project3
using Test
using Dates

@testset "addBooking" begin
    request = BookingRequest(
        "company-b", 3, "Origin", "Destination", "Goods",
        DateTime(2026, 10, 10, 8), DateTime(2026, 10, 10, 9),
        DateTime(2026, 10, 10, 10), DateTime(2026, 10, 10, 12), true,
    )

    @testset "valid booking is passed to persistence callback" begin
        saved_request = Ref{Union{BookingRequest, Nothing}}(nothing)
        result = addBooking(request; save_booking! = booking -> begin
            saved_request[] = booking
            "booking-123"
        end)

        @test result == "booking-123"
        @test saved_request[] === request
    end

    @testset "rejects invalid booking data before persistence" begin
        callback_called = Ref(false)
        invalid_request = BookingRequest(
            "company-b", 0, "Origin", "Destination", "Goods",
            DateTime(2026, 10, 10, 8), DateTime(2026, 10, 10, 9),
            DateTime(2026, 10, 10, 10), DateTime(2026, 10, 10, 12), true,
        )

        @test_throws ArgumentError addBooking(
            invalid_request;
            save_booking! = _ -> (callback_called[] = true; "should-not-save"),
        )
        @test !callback_called[]
    end

    @testset "rejects missing booking ID from persistence callback" begin
        @test_throws ArgumentError addBooking(request; save_booking! = _ -> nothing)
    end

    @testset "rejects invalid time ranges" begin
        bad_pickup_range = BookingRequest(
            "company-b", 3, "Origin", "Destination", "Goods",
            DateTime(2026, 10, 10, 9), DateTime(2026, 10, 10, 8),
            DateTime(2026, 10, 10, 10), DateTime(2026, 10, 10, 12), true,
        )
        @test_throws ArgumentError addBooking(bad_pickup_range; save_booking! = _ -> "unused")
    end
end
