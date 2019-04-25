
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

name_type_iter(x) = (s = Tables.schema(x); zip(s.names, s.types))

function InstancedProgram(
        context::AbstractContext, shader,
        instance::AbstractVector,
        per_instance::AbstractVector;
        uniforms...
    )

    # instance = convert_uniform(context, instance)
    # per_instance = convert_uniform(context, per_instance)
    c_uniforms = Dict{Symbol, Any}()
    src = sprint() do io
        println(io, "// Instance inputs: ")
        for (name, T) in name_type_iter(instance)
            println(io, "in ", type_string(context, T), " $name;")
        end

        println(io, "\n// Per instance attributes: ")
        for (name, T) in name_type_iter(per_instance)
            println(io, "in ", type_string(context, T), " $name;")
        end

        println(io, "\n// Uniforms: ")
        for (name, v) in uniforms
            vc = convert_uniform(context, v)
            T = typeof(vc)
            println(io, "uniform ", type_string(context, T), " $name;")
            c_uniforms[name] = vc
        end
        println(io)
        println(io, shader)
    end
    InstancedProgram(
        Program(context, instance, c_uniforms, src),
        per_instance
    )
end
