using ShaderAbstractions, LinearAlgebra
using ShaderAbstractions: VertexArray
using Test, GeometryTypes
import GeometryBasics

struct Bla <: ShaderAbstractions.AbstractContext end

m = GLNormalMesh(Sphere(Point3f0(0), 1f0))

mvao = VertexArray(m)
instances = VertexArray(positions = rand(GeometryBasics.Point{3, Float32}, 100))

x = ShaderAbstractions.InstancedProgram(
    Bla(),
    "void main(){}\n", "void main(){}\n",
    mvao,
    instances,
    model = GeometryTypes.Mat4f0(I),
    view = GeometryTypes.Mat4f0(I),
    projection = GeometryTypes.Mat4f0(I),

)

@test x.program.fragment_source == read(joinpath(@__DIR__, "test.frag"), String)
@test x.program.vertex_source == read(joinpath(@__DIR__, "test.vert"), String)
