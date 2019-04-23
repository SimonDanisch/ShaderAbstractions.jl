

is_scalar(array, field) = false

function instanced_program(
		context::AbstractContext, shader,
		instance::AbstractVector{Vertex},
		per_instance::AbstractVector{Instance};
		uniforms...
	) where {Vertex, Instance}

	return sprint() do io
		for name in (fieldnames(Vertex)..., fieldnames(Instance)...,)
			if is_scalar(instance, name)
				println(io, "uniform ", type_string(T), ";")
			else
				T = fieldtype(Vertex, name)
				println(io, "in ", type_string(T), ";")
			end
		end
		for (k, v) in uniforms
			println(io, "uniform ", type_string(T), ";")
		end
		println(io)
		println(io, shader)
	end
end
