using Project3
using Test

@testset "signup and login flow" begin
    datastore = Project3.UtilityFunctions
    original_database = deepcopy(datastore.database)
    original_file = read(datastore.DATABASE_PATH, String)

    try
        logout!()

        vehicle = addVehicle("authentication-test-vehicle", 8)
        new_user = sign_up("  auth-test-user  ", "secret", COMPANY)

        @test new_user.user_name == "auth-test-user"
        @test new_user.role == COMPANY
        @test new_user.vehicle_id === nothing
        @test !(:password in propertynames(new_user))
        @test current_session() === nothing

        logged_in_user = login(" auth-test-user ", "secret")
        @test logged_in_user == new_user
        @test current_session() == new_user
        @test login("auth-test-user", "incorrect") === nothing
        @test login("missing-auth-test-user", "secret") === nothing

        logout!()
        @test current_session() === nothing

        operator = sign_up("auth-test-operator", "secret", "vehicle operator";
            vehicle_id=vehicle["vehicle_id"])
        @test operator.role == VEHICLE_OPERATOR
        @test operator.vehicle_id == vehicle["vehicle_id"]
        @test login("auth-test-operator", "secret") == operator

        @test_throws ArgumentError sign_up("auth-test-user", "secret", COMPANY)
        @test_throws ArgumentError sign_up("", "secret", COMPANY)
        @test_throws ArgumentError sign_up("auth-test-empty-password", "", COMPANY)
        @test_throws ArgumentError sign_up("auth-test-no-vehicle", "secret", VEHICLE_OPERATOR)
        @test_throws ArgumentError sign_up("auth-test-bad-vehicle", "secret", VEHICLE_OPERATOR;
            vehicle_id="missing-vehicle")
        @test_throws ArgumentError sign_up("auth-test-company-vehicle", "secret", COMPANY;
            vehicle_id=vehicle["vehicle_id"])
        @test_throws ArgumentError login("", "secret")
        @test_throws ArgumentError login("auth-test-user", "")
    finally
        logout!()
        datastore.database = original_database
        write(datastore.DATABASE_PATH, original_file)
    end
end
