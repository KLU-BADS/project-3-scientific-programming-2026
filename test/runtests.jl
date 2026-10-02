using Project3
using Test
using Dates

# Every @testset that fails will be reported individually, so give them
# names that tell you what broke.

@testset "Project3.jl" begin

    @testset "hello" begin
        # hello() prints, so it returns nothing. What it prints is checked by
        # the jldoctest in its docstring, which runs when the docs are built.
        @test hello() === nothing
    end

    @testset "utility functions" begin
        cost_quote = calculateCost(10, 2; base_price_cents=100, price_per_km_cents=10, price_per_pallet_cents=5)
        @test cost_quote.amount_cents == 210
        @test fetchDistance("Port", "D1"; provider=(from, to) -> 42.5) == 42.5

        menu_output = IOBuffer()
        @test showMenu(role=:admin, input=IOBuffer("6\n"), output=menu_output) == :logout
        @test occursin("Show bookings", String(take!(menu_output)))
    end

    @testset "JSON collection datastore and authentication" begin
        datastore = Project3.UtilityFunctions
        original_database = deepcopy(datastore.database)
        original_file = read(datastore.DATABASE_PATH, String)

        try
            user_document = addMethod("users", User("", "datastore-test", "secret", COMPANY, nothing))
            @test getOneByParameter("users", :user_name, "datastore-test") == user_document
            @test only(getAllListing("users")) == user_document
            @test login("datastore-test", "secret").id == user_document["id"]
            @test login("datastore-test", "incorrect") === nothing

            vehicle_document = addVehicle("datastore-test-vehicle", 12)
            @test getOneByParameter("vehicles", "vehicle_id", vehicle_document["vehicle_id"]) == vehicle_document

            party = BookingParty(
                "company-1", vehicle_document["vehicle_id"], DateTime(2026, 9, 27),
                DateTime(2026, 9, 27, 1), DateTime(2026, 9, 28),
                DateTime(2026, 9, 28, 1), 4, 2500, "Destination", "Goods",
            )
            booking_document = addMethod(
                "bookings",
                Booking("", now(), nothing, user_document["id"], nothing, party, nothing, IN_PROGRESS),
            )
            @test getOneByParameter("bookings", "id", booking_document["id"]) == booking_document

            listing = VehicleListing(
                vehicle_document["vehicle_id"], booking_document["id"], "company-1", 4,
                12, "Destination", "Origin", DateTime(2026, 9, 27),
                DateTime(2026, 9, 27, 1), DateTime(2026, 9, 28), DateTime(2026, 9, 28, 1),
            )
            listing_document = addMethod("listings", listing)
            @test getOneByParameter("listings", "booking_id", booking_document["id"]) == listing_document

            invoice = Invoice(
                2500, "USD", "Company", "Origin", "Destination", vehicle_document["vehicle_id"],
                Date(2026, 9, 28), now(), "company-1",
            )
            invoice_document = addMethod("invoices", invoice)
            @test getOneByParameter("invoices", "invoice_for_company_id", "company-1") == invoice_document
        finally
            datastore.database = original_database
            write(datastore.DATABASE_PATH, original_file)
            logout!()
        end
    end

end
