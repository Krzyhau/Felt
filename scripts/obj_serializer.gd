class_name ObjSerializer

# returns an array of meshes contained in OBJ text
static func deserialize_from(text : String) -> Dictionary:
	
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var normals := PackedVector3Array()
	var all_faces := Dictionary()
	var current_faces := []
	
	var current_obj := ""
	
	for line in text.split("\n"):
		line = line.strip_edges(true, true)
		
		var params := line.split(" ")
		var paramcount := params.size()
		
		match params[0]:
			"o":
				if current_faces.size() > 0: all_faces[current_obj] = current_faces
				current_faces = []
				if params.size() > 1: current_obj = params[1]
			"v":
				vertices.append(Vector3(
					params[1].to_float() if paramcount > 3 else 0.0,
					params[2].to_float() if paramcount > 3 else 0.0,
					params[3].to_float() if paramcount > 3 else 0.0,
				))
			"vt": 
				uvs.append(Vector2(
					params[1].to_float() if paramcount > 2 else 0.0,
					params[2].to_float() if paramcount > 2 else 0.0,
				))
			"vn": 
				normals.append(Vector3(
					params[1].to_float() if paramcount > 3 else 0.0,
					params[2].to_float() if paramcount > 3 else 0.0,
					params[3].to_float() if paramcount > 3 else 0.0,
				))
			"f":
				for i in range(3):
					# Godot uses clockwise vertex ordering, while OBJ uses counter-clockwise
					var data_string : String = params[3-i] if (3-i) < params.size() else ""
					var data_params := data_string.split("/")
					var dataparamcount = data_params.size()
					current_faces.append(Vector3i(
						data_params[0].to_int() if dataparamcount > 0 else 0,
						data_params[1].to_int() if dataparamcount > 1 else 0,
						data_params[2].to_int() if dataparamcount > 2 else 0,
					))
	
	if current_faces.size() > 0: all_faces[current_obj] = current_faces
	
	return _generate_meshes(vertices, uvs, normals, all_faces)

static func _generate_meshes(
	vertices : PackedVector3Array,
	uvs : PackedVector2Array, 
	normals : PackedVector3Array, 
	faces : Dictionary
) -> Dictionary:
	var meshes := Dictionary()
	
	for key in faces:
		var mesh_vertices := PackedVector3Array()
		var mesh_uvs := PackedVector2Array()
		var mesh_normals := PackedVector3Array()
		
		for face in faces[key]:
			mesh_vertices.append(vertices[face.x - 1])
			mesh_uvs.append(uvs[face.y - 1])
			mesh_normals.append(normals[face.z - 1])
		
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
