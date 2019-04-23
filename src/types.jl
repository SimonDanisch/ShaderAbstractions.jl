
"""
Holder of Shader context info, can also be used for dispatch
"""
abstract type AbstractContext end

"""
A Sampler, that supports interpolated access
"""
abstract type AbstractSampler{T, N} <: DenseArray{T, N} end

abstract type AbstractSamplerBuffer{T} <: DenseVector{T} end


"""
VertexArray, holds the vertex info a vertex shaders maps over.
"""
abstract type AbstractVertexArray{T} <: DenseVector{T} end


struct Sampler{T, N} <: AbstractSampler{T, N}
	data::T
    minfilter::Symbol
    magfilter::Symbol # magnification
    repeat::NTuple{N, Symbol}
    anisotropic::Float32
    color_swizzel::Vector{Symbol}
end

struct BufferSampler{T} <: AbstractSamplerBuffer{T}
	data::T
end

struct VertexArray{T} <: AbstractVertexArray{T}
	data::T
end

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
	Sampler{T, N}(
		data, minfilter, magfilter,
		(x_reapt, y_repeat, z_repeat),
		anisotropic, swizzel
	)
end
