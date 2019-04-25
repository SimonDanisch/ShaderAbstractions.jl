using ShaderAbstractions, LinearAlgebra
using ShaderAbstractions: VertexArray
using Test

struct Bla <: ShaderAbstractions.AbstractContext end

import GeometryTypes, AbstractPlotting, GeometryBasics

m = GeometryTypes.GLNormalMesh(GeometryTypes.Sphere(GeometryTypes.Point3f0(0), 1f0))

mvao = VertexArray(m)
instances = VertexArray(positions = rand(GeometryBasics.Point{3, Float32}, 100))

x = ShaderAbstractions.InstancedProgram(
    Bla(), "hi",
    mvao,
    instances,
    
    model = GeometryTypes.Matf4f0(I),
    view = GeometryTypes.Matf4f0(I),
    projection = GeometryTypes.Matf4f0(I),

)

x.program.source |> println
