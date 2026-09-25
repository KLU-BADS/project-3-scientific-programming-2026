"""Business rules and CLI helpers for the collaborative-loading application."""
module UtilityFunctions

using Dates
using ..MongoDataStore: addRecord, getByKeyValue

include("models.jl")
include("calculateCost.jl")
include("fetchDistance.jl")
include("checkFeasibilityToAllowCompanyBToBookVehicle.jl")
include("addBooking.jl")
include("authentication.jl")
include("showMenu.jl")

export UserRole, BookingStatus, ADMIN, VEHICLE_OPERATOR, COMPANY
export COMPLETED, IN_PROGRESS, CANCELLED, NO_SHOW
export User, AuthenticatedUser, BookingParty, Booking, BookingRequest
export Vehicle, VehicleListing, Invoice, CostQuote, DeliveryFeasibility
export addBooking, authenticate, calculateCost, checkFeasibilityToAllowCompanyBToBookVehicle
export checkFeasabilityToAllowCompanyBToBookVehicle, fetchDistance, showMenu
export featureFunctionaility, featureFunctionality
export sign_up, login, logout!, current_session, run_authentication_cli
export signUp, logIn, logOut

end # module UtilityFunctions
