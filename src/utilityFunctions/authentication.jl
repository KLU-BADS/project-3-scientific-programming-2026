"""
    authenticate(email, password; find_user_by_email, verify_password) -> Union{AuthenticatedUser, Nothing}

Authenticate through injected repository and password-hash callbacks. Never
store, print, or compare plaintext passwords in application code.
"""
function authenticate(
    email::AbstractString,
    password::AbstractString;
    find_user_by_email::Function,
    verify_password::Function,
)
    normalized_email = lowercase(strip(email))
    isempty(normalized_email) && throw(ArgumentError("email cannot be empty."))
    isempty(password) && throw(ArgumentError("password cannot be empty."))

    user = find_user_by_email(normalized_email)
    isnothing(user) && return nothing
    verify_password(password, user) || return nothing
    user isa AuthenticatedUser || throw(ArgumentError("find_user_by_email must return AuthenticatedUser or nothing."))
    user.role in (:client, :admin) || throw(ArgumentError("user role must be :client or :admin."))
    return user
end
