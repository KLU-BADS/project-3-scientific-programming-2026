using Project3
using Test

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

end
