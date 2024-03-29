class_name ObjSerializer

# Returns a list of mesh arrays contained in OBJ text,
# interpreting each OBJ's object as a separate mesh.
# Simplified for custom Trixel Art format reading.
static func deserialize_from(text : String) -> Dictionary:
	
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var normals := PackedVector3Array()
	var all_faces := Dictionary()
	var current_faces := PackedInt32Array()
	
	var current_obj := ""
	
	for line : String in text.split("\n", false):
		line = line.strip_edges(true, true)
		
		if line.begins_with("v "):
			var values := line.substr(2).split_floats(" ", false)
			values.resize(3)
			vertices.append(Vector3(values[0], values[1], values[2]))
		elif line.begins_with("vt "):
			var values := line.substr(3).split_floats(" ", false)
			values.resize(2)
			uvs.append(Vector2(values[0], values[1]))
		elif line.begins_with("vn "):
			var values := line.substr(3).split_floats(" ", false)
			values.resize(3)
			normals.append(Vector3(values[0], values[1], values[2]))
		elif line.begins_with("f "):
			var params := line.split(" ", false)
			# Godot uses clockwise vertex ordering, while OBJ uses counter-clockwise,
			# so order is reversed here. Additionally, all extra vertices are ignored,
			# as exported trixel formats are expected to be triangulated.
			for i in range(3,0,-1):
				if i >= params.size(): 
					current_faces.append_array([0,0,0])
					continue
				var data_params := params[i].split_floats("/")
				data_params.resize(3)
				current_faces.append(int(data_params[0]) - 1)
				current_faces.append(int(data_params[1]) - 1)
				current_faces.append(int(data_params[2]) - 1)
			
		elif line.begins_with("o "):
			if current_faces.size() > 0: all_faces[current_obj] = current_faces
			current_faces = []
			if line.length() > 2: current_obj = line.substr(2)
	
	if current_faces.size() > 0: all_faces[current_obj] = current_faces
	
	var meshes := Dictionary()
	
	for key in all_faces:
		var mesh_vertices := PackedVector3Array()
		var mesh_uvs := PackedVector2Array()
		var mesh_normals := PackedVector3Array()
		
		var face : PackedInt32Array = all_faces[key]
		
		for i in range(0, face.size(), 3):
			mesh_vertices.append(vertices[face[i]])
			mesh_uvs.append(uvs[face[i+1]])
			mesh_normals.append(normals[face[i+2]])
		
		var _mesh_data := []
		_mesh_data.resize(Mesh.ARRAY_MAX)
		_mesh_data[Mesh.ARRAY_VERTEX] = mesh_vertices
		_mesh_data[Mesh.ARRAY_TEX_UV] = mesh_uvs
		_mesh_data[Mesh.ARRAY_NORMAL] = mesh_normals
		meshes[key] = _mesh_data
	
	return meshes



# serializes an array of meshes into OBJ text
static func serialize_to(meshes : Array) -> String:
	return ""
