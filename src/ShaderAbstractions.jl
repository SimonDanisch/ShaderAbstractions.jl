module ShaderAbstractions

using StaticArrays, ColorTypes, FixedPointNumbers, StructArrays, Observables
import GeometryBasics, Tables

include("types.jl")
include("uniforms.jl")
include("context.jl")
include("program.jl")

end # module
