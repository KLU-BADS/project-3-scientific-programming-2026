"""
Reusable, schema-less MongoDB access helpers.

Connection settings are loaded from the project-root `.env` file. Set
`MONGO_URL` to a MongoDB connection URI and either put the database name in
that URI or set `MONGO_DATABASE` explicitly.
"""
module MongoDataStore

using DotEnv
using Mongoc

export addRecord, getFunction, getOneById, getByKeyValue, getAll

const ENV_FILE = normpath(joinpath(@__DIR__, "..", ".env"))

"Load local environment variables without overwriting values supplied by the host."
function _load_environment!()
    isfile(ENV_FILE) && DotEnv.load!(ENV_FILE)
    return nothing
end

function _mongo_settings()
    _load_environment!()
    mongo_url = get(ENV, "MONGO_URL", nothing)
    isnothing(mongo_url) && throw(ArgumentError("MONGO_URL is required; add it to .env or the environment."))

    database_name = get(ENV, "MONGO_DATABASE", nothing)
    if isnothing(database_name)
        # The database is the first path segment after the MongoDB host list.
        match_result = match(r"^mongodb(?:\+srv)?://[^/]+/([^?/#]+)", mongo_url)
        database_name = isnothing(match_result) ? nothing : match_result.captures[1]
    end
    isnothing(database_name) && throw(ArgumentError(
        "Set MONGO_DATABASE or include a database name in MONGO_URL, e.g. mongodb://localhost:27017/logistics."
    ))
    isempty(database_name) && throw(ArgumentError("MONGO_DATABASE cannot be empty."))
    return mongo_url, database_name
end

"Run an operation with a short-lived MongoDB client and always release it."
function _with_collection(collection_name::AbstractString, operation::Function)
    isempty(collection_name) && throw(ArgumentError("collection_name cannot be empty."))
    mongo_url, database_name = _mongo_settings()
    client = Mongoc.Client(mongo_url)
    try
        return operation(client[database_name][String(collection_name)])
    finally
        Mongoc.destroy!(client)
    end
end

_as_bson(document::Mongoc.BSON) = document
function _as_bson(document::AbstractDict)
    # Mongoc accepts dictionaries directly; normalize keys so JSON-style Symbol
    # keys work too.
    normalized = Dict{String, Any}(String(key) => value for (key, value) in document)
    return Mongoc.BSON(normalized)
end

function _object_id(id)
    id isa Mongoc.BSONObjectId && return id
    id isa AbstractString || throw(ArgumentError("id must be a MongoDB ObjectId or its 24-character string form."))
    return Mongoc.BSONObjectId(id)
end

"""
    addRecord(collectionName, document) -> BSONObjectId

Insert a schema-less dictionary/BSON document into `collectionName` and return
MongoDB's generated `_id`.
"""
function addRecord(collectionName::AbstractString, document::Union{AbstractDict, Mongoc.BSON})
    return _with_collection(collectionName) do collection
        Mongoc.insert_one(collection, _as_bson(document)).inserted_oid
    end
end

"Compatibility name for inserting a document; use `addRecord` in new code."
getFunction(collectionName::AbstractString, document::Union{AbstractDict, Mongoc.BSON}) =
    addRecord(collectionName, document)

"""
    getOneById(collectionName, id) -> Union{Mongoc.BSON, Nothing}

Return the document with MongoDB `_id` `id`, or `nothing` when it does not exist.
"""
function getOneById(collectionName::AbstractString, id)
    return _with_collection(collectionName) do collection
        Mongoc.find_one(collection, Mongoc.BSON("_id" => _object_id(id)))
    end
end

"""
    getByKeyValue(collectionName, key, value; page=1, pageSize=20) -> Vector{Mongoc.BSON}

Return matching documents for one field, using one-based pagination.
"""
function getByKeyValue(
    collectionName::AbstractString,
    key::AbstractString,
    value;
    page::Integer=1,
    pageSize::Integer=20,
)
    return getAll(collectionName; filter=Dict(String(key) => value), page=page, pageSize=pageSize)
end

"""
    getAll(collectionName; filter=Dict(), page=1, pageSize=20) -> Vector{Mongoc.BSON}

Return one page of records. `filter` is optional and supports MongoDB query
operators when supplied as BSON.
"""
function getAll(
    collectionName::AbstractString;
    filter::Union{AbstractDict, Mongoc.BSON}=Dict{String, Any}(),
    page::Integer=1,
    pageSize::Integer=20,
)
    page < 1 && throw(ArgumentError("page must be at least 1."))
    pageSize < 1 && throw(ArgumentError("pageSize must be at least 1."))
    options = Mongoc.BSON("skip" => (page - 1) * pageSize, "limit" => pageSize)
    return _with_collection(collectionName) do collection
        collect(Mongoc.find(collection, _as_bson(filter); options=options))
    end
end

end # module MongoDataStore
