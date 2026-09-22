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
export AuthenticatedUser, BookingRequest, CostQuote, DeliveryFeasibility, VehicleListing
export addBooking, authenticate, calculateCost, checkFeasibilityToAllowCompanyBToBookVehicle
export checkFeasabilityToAllowCompanyBToBookVehicle, fetchDistance, showMenu

using .MongoDataStore: addRecord, getFunction, getOneById, getByKeyValue, getAll
using .UtilityFunctions: AuthenticatedUser, BookingRequest, CostQuote, DeliveryFeasibility, VehicleListing
using .UtilityFunctions: addBooking, authenticate, calculateCost, checkFeasibilityToAllowCompanyBToBookVehicle
using .UtilityFunctions: checkFeasabilityToAllowCompanyBToBookVehicle, fetchDistance, showMenu

end # module Project3
