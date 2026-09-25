"""
    Project3

A minimal Julia package to start a project from.
"""
module Project3

# Files to be included
include("hello.jl")
include(joinpath(@__DIR__, "..", "menu", "mongoDataStore.jl"))
include("utilityFunctions/utilityFunctions.jl")

# Functions to be exported
export hello
export MongoDataStore
export addRecord, getFunction, getOneById, getByKeyValue, getAll
export UtilityFunctions
export UserRole, BookingStatus, ADMIN, VEHICLE_OPERATOR, COMPANY
export COMPLETED, IN_PROGRESS, CANCELLED, NO_SHOW
export User, AuthenticatedUser, BookingParty, Booking, BookingRequest
export Vehicle, VehicleListing, Invoice, CostQuote, DeliveryFeasibility
export addBooking, authenticate, calculateCost, checkFeasibilityToAllowCompanyBToBookVehicle
export checkFeasabilityToAllowCompanyBToBookVehicle, fetchDistance, showMenu
export featureFunctionaility, featureFunctionality
export sign_up, login, logout!, current_session, run_authentication_cli
export signUp, logIn, logOut

using .MongoDataStore: addRecord, getFunction, getOneById, getByKeyValue, getAll
using .UtilityFunctions: UserRole, BookingStatus, ADMIN, VEHICLE_OPERATOR, COMPANY
using .UtilityFunctions: COMPLETED, IN_PROGRESS, CANCELLED, NO_SHOW
using .UtilityFunctions: User, AuthenticatedUser, BookingParty, Booking, BookingRequest
using .UtilityFunctions: Vehicle, VehicleListing, Invoice, CostQuote, DeliveryFeasibility
using .UtilityFunctions: addBooking, authenticate, calculateCost, checkFeasibilityToAllowCompanyBToBookVehicle
using .UtilityFunctions: checkFeasabilityToAllowCompanyBToBookVehicle, fetchDistance, showMenu
using .UtilityFunctions: featureFunctionaility, featureFunctionality
using .UtilityFunctions: sign_up, login, logout!, current_session, run_authentication_cli
using .UtilityFunctions: signUp, logIn, logOut

end # module Project3
