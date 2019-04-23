using ShaderAbstractions
using Test

struct Bla <: ShaderAbstractions.AbstractContext end

ShaderAbstractions.instanced_program(
    Bla(), "hi",
    [(a = 22, b = SVector(1, 2, 3))],
    [(a = 22, b = SVector(1, 2, 3))],
)
