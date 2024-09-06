
"""
Holder of Shader context info, can also be used for dispatch
"""
abstract type AbstractContext end

"""
Array that has an update objects, one can register to with `conncet!(x::UpdatableArray, y::AbstractArray)`
To register to changes to the array.
Any UpdatableArray needs to implement updater to return the updatable object
"""
abstract type UpdatableArray{T, N} <: AbstractArray{T, N} end

"""
Get's the updater object of an updatable array
"""
function updater end
connect!(x::UpdatableArray, y::AbstractArray) = connect!(updater(x), y)


"""
A Sampler, that supports interpolated access
"""
abstract type AbstractSampler{T, N} <: UpdatableArray{T, N} end

abstract type AbstractSamplerBuffer{T} <: UpdatableArray{T, 1} end


"""
VertexArray, holds the vertex info a vertex shaders maps over.
"""
abstract type AbstractVertexArray{T} <: UpdatableArray{T, 1} end

struct ArrayUpdater{T}
    parent::T
    update::Observable{Tuple{Function, Tuple}}
end

function ArrayUpdater(x::T) where T <: AbstractArray
    ArrayUpdater{T}(x, Observable{Tuple{Function, Tuple}}((identity, ())))
end

for func in (:resize!, :push!, :setindex!)
    @eval function Base.$(func)(vec::ArrayUpdater, args...)
        $(func)(vec.parent, args...)
        vec.update[] = ($(func), args)
        return vec.parent
    end
end

function connect!(au::ArrayUpdater, array::AbstractArray)
    on(au.update) do (f, args)
        f(array, args...)
    end
end

macro update_operations(Typ)
    quote
        Base.setindex!(A::$Typ, value, idx...) = setindex!(updater(A), value, idx...)
        Base.push!(A::$Typ, value) = push!(updater(A), value)
        Base.resize!(A::$Typ, value) = resize!(updater(A), value)
        Base.size(A::$Typ) = size(updater(A).parent)
        Base.getindex(A::$Typ, idx...) = getindex(updater(A).parent, idx...)
    end
end

mutable struct Sampler{T, N, Data} <: AbstractSampler{T, N}
    data::Data
    minfilter::Symbol
    magfilter::Symbol # magnification
    repeat::NTuple{N, Symbol}
    anisotropic::Float32
    color_swizzel::Vector{Symbol}
    updates::ArrayUpdater{Data}
end
data(x::Sampler) = getfield(x, :data)
updater(x::Sampler) = x.updates
@update_operations Sampler

function Sampler(
        data::AbstractArray{T, N};
        minfilter = T <: Integer ? :nearest : :linear,
        magfilter = minfilter, # magnification
        x_repeat  = :clamp_to_edge, #wrap_s
        y_repeat  = x_repeat, #wrap_t
        z_repeat  = x_repeat, #wrap_r
        anisotropic = 1f0,
        color_swizzel = nothing
    ) where {T, N}

    swizzel = color_swizzel !== nothing ? color_swizzel : if T <: Gray
        Symbol[:RED, :RED, :RED, :ONE]
    elseif T <: GrayA
        Symbol[:RED,:_RED, :RED, :ALPHA]
    else
        Symbol[]
    end
    Sampler{T, N, typeof(data)}(
        data, minfilter, magfilter,
        ntuple(i-> (x_repeat, y_repeat, z_repeat)[i], N),
        anisotropic, swizzel,
        ArrayUpdater(data)
    )
end

# Fallback
function update!(dest::AbstractArray, src::AbstractArray)
    if length(dest) != length(src)
        resize!(dest, length(src))
    end
    copy!(dest, src)
end

function update!(s::Sampler{T,N,D}, new_data::AbstractArray{T2,N}) where {T,T2,N,D}
    setfield!(s, :data, convert(D, new_data))
    updater(s).update[] = (update!, (data(s),))
end


function Sampler(obs::Observable; kw...)
    buff = Sampler(obs[]; kw...)
    on(obs) do val
        update!(buff, val)
    end
    return buff
end

struct BufferSampler{T, Data} <: AbstractSamplerBuffer{T}
    data::Data
    updates::ArrayUpdater{Data}
end
updater(x::BufferSampler) = getfield(x, :updates)
@update_operations BufferSampler

struct Buffer{T, Data} <: UpdatableArray{T, 1}
    data::Data
    updates::ArrayUpdater{Data}
end
updater(x::Buffer) = getfield(x, :updates)
@update_operations Buffer

Base.convert(::Type{<: Buffer}, x::Buffer) = x
Base.convert(::Type{<: Buffer}, x) = Buffer(x)
Base.convert(::Type{<: Buffer{T, Data}}, x::Buffer{T, Data}) where {T, Data} = x
data(x::Buffer) = getfield(x, :data)
function Base.getproperty(x::Buffer, name::Symbol)
    return getproperty(data(x), name)
end

function Base.propertynames(x::Buffer)
    return propertynames(data(x))
end

Buffer(x::Buffer) = x

function update!(buff::Buffer, new_data::AbstractVector)
    if length(buff) != length(new_data)
        resize!(data(buff), length(new_data))
    end
    copy!(data(buff), new_data)
    updater(buff).update[] = (update!, (data(buff),))
end

function Buffer(obs::Observable)
    buff = Buffer(obs[])
    on(obs) do val
        update!(buff, val)
    end
    buff
end

function Buffer(data::Data) where Data <: AbstractVector
    Buffer{eltype(data), Data}(data, ArrayUpdater(data))
end

struct VertexArray{T, Data} <: AbstractVertexArray{T}
    data::Data
end

Tables.schema(va::VertexArray) = Tables.schema(getfield(va, :data))

function Tables.columns(vao::VertexArray)
    s = Tables.schema(vao)
    return NamedTuple{s.names}(map(x-> getproperty(vao, x), s.names))
end

function Base.pairs(vao::VertexArray)
    nt = Tables.columns(vao)
    return zip(keys(nt), values(nt))
end

function Base.pairs(vao::VertexArray{T, <: Dict}) where T
    data = getfield(vao, :data)
    _keys = filter(k -> k != :faces, collect(keys(data)))
    return zip(_keys, getindex.(Ref(data), _keys))
end

function Base.getproperty(x::VertexArray, name::Symbol)
    getproperty(getfield(x, :data), name)
end

function Base.propertynames(x::VertexArray)
    propertynames(getfield(x, :data))
end

Base.size(x::VertexArray) = size(get(getfield(x, :data), :faces, getfield(x, :data)))
Base.getindex(x::VertexArray, i) = getindex(get(getfield(x, :data), :faces, getfield(x, :data)), i)

function VertexArray(data::AbstractArray{T}) where T
    return VertexArray{T, typeof(data)}(data)
end

# function VertexArray(points, faces = nothing; kw_args...)
#     vertices = if isempty(kw_args)
#         points
#     else
#         GeometryBasics.meta(points; kw_args...)
#     end
#     data = if faces === nothing
#         vertices
#     else
#         GeometryBasics.connect(vertices, faces)
#     end
#     return VertexArray(data)
# end

function VertexArray(attribs::NamedTuple, faces::AbstractVector)
    data = Dict{Symbol, Any}(pairs(attribs))
    data[:faces] = faces
    return VertexArray{Float32, typeof(data)}(data)
end

function VertexArray(; meta...)
    buffers = map(Buffer, values(meta))
    m = StructArray(; buffers...)
    return VertexArray(m)
end
