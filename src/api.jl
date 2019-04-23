
struct Program
    context::AbstractContext
    vertexarray::AbstractArray
    uniforms::Dict{Symbol, Any}
    source::String
end

struct InstancedProgram
    program::Program
    per_instance::AbstractArray
end


function InstancedProgram(
        context::AbstractContext, shader,
        instance::AbstractVector,
        per_instance::AbstractVector;
        uniforms...
    )

    instance = convert_uniform(context, instance)
    Vertex = eltype(instance)
    per_instance = convert_uniform(context, per_instance)
    Instance = eltype(per_instance)
    uniforms = Dict{Symbol, Any}()
    src = sprint() do io
        for name in (fieldnames(Vertex)..., fieldnames(Instance)...,)
            T = fieldtype(Vertex, name)
            println(io, "in ", type_string(context, T), " $name;")
        end
        for (k, v) in uniforms
            vc = convert_uniform(context, v)
            T = typeof(vc)
            println(io, "uniform ", type_string(context, T), " $name;")
            uniforms[k] = vc
        end
        println(io)
        println(io, shader)
    end
    InstancedProgram(
        Program(context, uniforms, src, instance),
        per_instance
    )
end
