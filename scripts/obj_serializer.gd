class_name ObjSerializer

# returns an array of meshes contained in OBJ text
static func deserialize_from(text : String) -> Dictionary:
	
	var vertices := []
	var uvs := []
	var normals := []
	var all_faces := Dictionary()
	var current_faces := []
	
	var current_obj = ""
	
	for line in text.split("\n"):
		line = line.strip_edges(true, true)
		
		var params := line.split(" ")
		
		match params[0]:
			"o":
				if current_faces.size() > 0: all_faces[current_obj] = current_faces
				current_faces = []
				if params.size() > 1: current_obj = params[1]
			"v": 
				vertices.append(_parse_vector3(params))
			"vt": 
				uvs.append(_parse_vector2(params))
			"vn": 
				normals.append(_parse_vector3(params))
			"f":
				current_faces.append_array(_parse_faces(params))
	
	if current_faces.size() > 0: all_faces[current_obj] = current_faces
	
	return _generate_meshes(vertices, uvs, normals, all_faces)

static func _parse_vector2(params : Array) -> Vector2:
	var vector := Vector2(0.0, 0.0)
	if params.size() > 1 and params[1].is_valid_float(): vector.x = params[1].to_float()
	if params.size() > 2 and params[2].is_valid_float(): vector.y = params[2].to_float()
	return vector
	
static func _parse_vector3(params : Array) -> Vector3:
	var vector := Vector3(0.0, 0.0, 0.0)
	if params.size() > 1 and params[1].is_valid_float(): vector.x = params[1].to_float()
	if params.size() > 2 and params[2].is_valid_float(): vector.y = params[2].to_float()
	if params.size() > 3 and params[3].is_valid_float(): vector.z = params[3].to_float()
	return vector

static func _parse_faces(params: Array) -> Array:
	var vectors := []
	for i in range(3):
		var data_string : String = params[i+1] if i <= params.size() else ""
		var data_params := data_string.split("/")
		var vector := Vector3i(0,0,0)
		if data_params.size() > 0: vector.x = data_params[0].to_int()
		if data_params.size() > 1: vector.y = data_params[1].to_int()
		if data_params.size() > 2: vector.z = data_params[2].to_int()
		vectors.append(vector)
		
	# Godot uses clockwise vertex ordering, while OBJ uses counter-clockwise
	vectors.reverse()
	
	return vectors

static func _generate_meshes(
	vertices : Array, uvs : Array, normals : Array, faces : Dictionary
) -> Dictionary:
	var meshes := Dictionary()
	
	for key in faces:
		var _mesh_data := []
		_mesh_data.resize(Mesh.ARRAY_MAX)
		_mesh_data[Mesh.ARRAY_VERTEX] = PackedVector3Array()
		_mesh_data[Mesh.ARRAY_TEX_UV] = PackedVector2Array()
		_mesh_data[Mesh.ARRAY_NORMAL] = PackedVector3Array()
		
		for face in faces[key]:
			_mesh_data[Mesh.ARRAY_VERTEX].append(vertices[face.x - 1])
			_mesh_data[Mesh.ARRAY_TEX_UV].append(uvs[face.y - 1])
			_mesh_data[Mesh.ARRAY_NORMAL].append(normals[face.z - 1])
			
		meshes[key] = _mesh_data
	
	return meshes



# serializes an array of meshes into OBJ text
static func serialize_to(meshes : Array) -> String:
	return ""
