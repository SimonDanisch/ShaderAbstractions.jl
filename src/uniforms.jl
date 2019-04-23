
# All the types native to ogl, wgl and vulkan shaders

const number_types = (Float32, Cint, Cuint, Cdouble)
const small_vecs = ((StaticVector{N, T} for T in number_types, N in (2, 3, 4))...,)
const small_mats = (SArray{Tuple{i, j}, T, 2, i * j} for T in number_types, i in (2, 3, 4), j in (2, 3, 4)...)
const small_arrays = (small_vecs..., small_mats...)
const native_types = (number_types..., small_arrays...)

const NativeNumbers = Union{number_types...}
const SmallVecs = Union{small_vecs...}
const SmallMats = Union{small_mats...}
const SmallArrays = Union{small_arrays...}
const NativeTypes = Union{native_types...}


"""
Returns a native type for a non native type.
E.g. native_type(Int128) -> Cint
"""
native_type(::Type{T}) where T <: NativeTypes = T

native_type(x::Type{T}) where {T <: Integer} = Cint
native_type(x::Type{Union{Int16, Int8}}) = x

native_type(x::Type{T}) where {T <: Unsigned} = Cuint
native_type(x::Type{Union{UInt16, UInt8}})  = x

native_type(x::Type{T}) where {T <: AbstractFloat} = Float32
native_type(x::Type{Float16})               = x

native_type(x::Type{T}) where T <: Normed = N0f32
native_type(x::Type{N0f16}) = x
native_type(x::Type{N0f8}) = x

native_type(x::Type{<: StaticArray{S, T, N}}) where {S, T, N} = similar_type(x, native_type(T))

map_t(f, tuple) = map_t(f, (), tuple)
map_t(f, result, ::Type{Tuple{}}) = Tuple{result...}
function map_t(f, result, T::Type{<: Tuple})
	map_t(
		f,
		(result..., f(Base.tuple_type_head(T))),
		Base.tuple_type_tail(T)
	)
end

function native_type(::Type{NamedTuple{Names, Types}}) where {Names, Types}
	return NamedTuple{Names, map_t(native_type, Types)}
end

"""
All native types don't need conversion
"""
convert_uniform(x::NativeTypes) = x

"""
Vector of native types, e.g `vec3 [4]`
"""
convert_uniform(x::StaticVector{N, T}) where {N, T <: NativeTypes} = x

"""
Static Array with non native uniform type
"""
function convert_uniform(x::StaticVector{N, T}) where {N, T}
	convert(similar_type(x, native_type(T)), x)
end

"""
Colors get special treatment to get them as vecs in shaders
"""
convert_uniform(x::Colorant{T}) where T <: NativeNumbers = x

convert_uniform(x::Colorant{T}) where T = return mapc(native_type(T), x)

function convert_uniform(x::AbstractVector{T}) where T
	return convert(Vector{native_type(T)}, x)
end

function convert_uniform(x::NamedTuple{Names, Types}) where {Names, Types}
	return map(convert_uniform, x)
end
function convert_uniform(x::T) where T
	all(t-> isbits(t), fieldtypes(T)) || error("All field types need to be isbits. Found: $(T) with $(fieldtypes(T))")
	return x
end


type_prefix(x::Type{T}) where {T <: Union{FixedPoint, Float32, Float16}} = ""
type_prefix(x::Type{T}) where {T <: Float64} = "d"
type_prefix(x::Type{Cint}) = "i"
type_prefix(x::Type{T}) where {T <: Union{Cuint, UInt8, UInt16}} = "u"

type_postfix(x::Type{Float64}) = "dv"
type_postfix(x::Type{Float32}) = "fv"
type_postfix(x::Type{Cint})    = "iv"
type_postfix(x::Type{Cuint})   = "uiv"


type_string(x::T) where {T} = type_string(T)
type_string(t::Type{Float32}) = "float"
type_string(t::Type{Float64}) = "double"
type_string(t::Type{Cuint}) = "uint"
type_string(t::Type{Cint}) = "int"

function type_string(t::Type{T}) where {T <: Union{StaticVector, Colorant}}
	return string(type_prefix(eltype(T)), "vec", length(T))
end

function type_string(t::Type{<: AbstractSamplerBuffer{T}}) where T
	string(type_prefix(eltype(T)), "samplerBuffer")
end

function type_string(t::Type{<: AbstractSampler{T, D}}) where {T, D}
    str = string(type_prefix(eltype(T)), "sampler", D, "D")
    is_arraysampler(t) && (str *= "Array")
    return str
end

function type_string(t::Type{<: StaticMatrix})
    M, N = size(t)
    string(type_prefix(eltype(t)), "mat", M == N ? M : string(M, "x", N))
end

type_string(t::Type) = error("Type $t not supported")
