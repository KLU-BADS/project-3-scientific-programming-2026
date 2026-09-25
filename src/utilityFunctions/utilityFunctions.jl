"""Business rules and CLI helpers for the collaborative-loading application."""
module UtilityFunctions

using Dates

include("models.jl")
include("calculateCost.jl")
include("fetchDistance.jl")
include("checkFeasibilityToAllowCompanyBToBookVehicle.jl")
include("addBooking.jl")
include("authentication.jl")
include("showMenu.jl")

export AuthenticatedUser, BookingRequest, CostQuote, DeliveryFeasibility, VehicleListing
export addBooking, authenticate, calculateCost, checkFeasibilityToAllowCompanyBToBookVehicle
export checkFeasabilityToAllowCompanyBToBookVehicle, fetchDistance, showMenu

end # module UtilityFunctions
