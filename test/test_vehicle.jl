using Project3
using Test

@testset "addVehicle" begin
    datastore = Project3.UtilityFunctions
    original_database = deepcopy(datastore.database)
    original_file = read(datastore.DATABASE_PATH, String)

    try
        vehicle = addVehicle("vehicle-test-truck", 12)

        @test vehicle["vehicle_name"] == "vehicle-test-truck"
        @test vehicle["vehicle_capacity"] == 12
        @test !isempty(vehicle["vehicle_id"])
        @test getVehicle(vehicle["vehicle_id"]) == vehicle

        default_capacity_vehicle = addVehicle("vehicle-test-default")
        @test default_capacity_vehicle["vehicle_capacity"] == 30

        @test_throws ArgumentError addVehicle("vehicle-test-truck", 8)
        @test_throws ArgumentError addVehicle("   ", 8)
        @test_throws ArgumentError addVehicle("vehicle-test-invalid-capacity", 0)
    finally
        datastore.database = original_database
        write(datastore.DATABASE_PATH, original_file)
    end
end
