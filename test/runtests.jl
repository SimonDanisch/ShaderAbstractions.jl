using ShaderAbstractions
using ShaderAbstractions: VertexArray
using Test

struct Bla <: ShaderAbstractions.AbstractContext end

import GeometryTypes, AbstractPlotting, GeometryBasics

m = GeometryTypes.GLNormalMesh(GeometryTypes.Sphere(GeometryTypes.Point3f0(0), 1f0))


mvao = VertexArray(m)
instances = VertexArray(positions = rand(GeometryBasics.Point{3, Float32}, 100))

GeometryBasics.coordinates(mvao.data).normals
using Tables
GeometryBasics.column_names(mvao)
GeometryBasics.column_types(mvao)

Tables.schema(mvao)

ShaderAbstractions.InstancedProgram(
    Bla(), "hi",
    mvao,
    instances,
