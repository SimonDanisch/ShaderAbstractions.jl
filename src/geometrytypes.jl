import GeometryTypes

function VertexArray(mesh::GeometryTypes.AbstractMesh)
    data = GeometryTypes.attributes(mesh)
    vs = GeometryBasics.Point.(pop!(data, :vertices))
    fs = convert(Vector{GeometryBasics.TriangleFace{Cuint}}, pop!(data, :faces))
    m = GeometryBasics.Mesh(GeometryBasics.meta(vs; data...), fs)
    return VertexArray(m)
end

function VertexArray(mesh_obs::Observable)
    mesh = mesh_obs[]
    meta_keys = setdiff(keys(GeometryTypes.attributes(mesh)), [:vertices, :faces])
    vs = Buffer(map(mesh_obs) do mesh
        GeometryBasics.Point.(GeometryTypes.vertices(mesh))
    end)
    fs = Buffer(map(mesh_obs) do mesh
        convert(Vector{GeometryBasics.GLTriangleFace}, GeometryTypes.faces(mesh))
    end)
    meta = (k => Buffer(map(x-> GeometryTypes.attributes(x)[k], mesh_obs)) for k in meta_keys)
    m = GeometryBasics.Mesh(GeometryBasics.meta(vs; meta...), fs)
    return VertexArray(m)
end
