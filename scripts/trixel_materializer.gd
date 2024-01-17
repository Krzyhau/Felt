class_name TrixelMaterializer extends MeshInstance3D

var _trixels : TrixelContainer

var _trixel_layer_lookup : Array

func _generate_mesh():
	
	var start = Time.get_ticks_usec()
	
	var mesh_arrays = []
	mesh_arrays.resize(Mesh.ARRAY_MAX)
	mesh_arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array()
	mesh_arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array()
	mesh_arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array()
	_generate_mesh_data(mesh_arrays)
	
	mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arrays)

	var end = Time.get_ticks_usec()
	var worker_time = (end-start)/1000.0
	print("_generate_mesh() - %f ms" % worker_time)

func _generate_mesh_data(mesh_arrays : Array):
	_generate_trixel_layers_lookup()
	
	for face in 6:
		var layer_dir = TrixelContainer.get_face_normal(face).abs()
		var layer_dir_depth = _trixels.get_trixel_width_along_axis(layer_dir)
		
		for layer in layer_dir_depth:
			_generate_layer_mesh(mesh_arrays, face, layer)

	
func _generate_layer_mesh(mesh_arrays : Array, face : TrixelContainer.Face, depth : int):
	var planes = _find_planes_in_layer(face, depth);
	for plane in planes: _add_plane_to_mesh(mesh_arrays, plane)


func _find_planes_in_layer(face : TrixelContainer.Face, depth : int) -> Array:
	var dir_x = TrixelContainer.get_face_tangent(face).abs()
	var dir_y = TrixelContainer.get_face_cotangent(face).abs()

	var layer_size_x = _trixels.get_trixel_width_along_axis(dir_x)
	var layer_size_y = _trixels.get_trixel_width_along_axis(dir_y)
	
	var trixel_faces = _get_trixel_faces_map(face, depth)
	
	var planes = []
	while trixel_faces.size() > 0:
		var plane_position = trixel_faces.keys()[0]
		trixel_faces.erase(plane_position)
		var plane_x = 1
		var plane_y = 1
		while plane_x < layer_size_x:
			var face_pos = plane_position + dir_x * plane_x
			if trixel_faces.has(face_pos):
				trixel_faces.erase(face_pos)
				plane_x += 1
			else: break
		
		while plane_y < layer_size_y:
			var face_pos_y = plane_position + dir_y * plane_y
			var valid_faces = []
			for x in plane_x:
				var face_pos_x = face_pos_y + dir_x * x
				if trixel_faces.has(face_pos_x):
					valid_faces.append(face_pos_x)
				else: break
			if len(valid_faces) != plane_x: 
				break
			for face_pos_x in valid_faces: 
				trixel_faces.erase(face_pos_x)
			plane_y += 1
		
		planes.append({
			position = plane_position,
			size = Vector2i(plane_x, plane_y),
			face = face
		})
	return planes

func _get_trixel_faces_map(face : TrixelContainer.Face, depth : int) -> Dictionary:
	var dir_x = TrixelContainer.get_face_tangent(face)
	var dir_y = TrixelContainer.get_face_cotangent(face)
	var dir_z = TrixelContainer.get_face_normal(face)

	var layer_size_x = _trixels.get_trixel_width_along_axis(dir_x)
	var layer_size_y = _trixels.get_trixel_width_along_axis(dir_y)
	var layer_size_z = _trixels.get_trixel_width_along_axis(dir_z)

	var depth_offset = (dir_z.x + dir_z.y + dir_z.z)
	var has_top = depth + 1 < layer_size_z

	var bounds = _trixels.trixel_bounds
	var global_y_scale = bounds.x
	var global_z_scale = bounds.x * bounds.y
	
	var x_scale = 1
	if dir_x.y != 0: x_scale = global_y_scale
	elif dir_x.z != 0: x_scale = global_z_scale
	
	var y_scale = 1
	if dir_y.y != 0: y_scale = global_y_scale
	elif dir_y.z != 0: y_scale = global_z_scale
	
	var z_scale = 1
	if dir_z.y != 0: z_scale = global_y_scale
	elif dir_z.z != 0: z_scale = global_z_scale

	var z_offset = depth if depth_offset > 0 else layer_size_z - 1 - depth
	z_offset *= z_scale
	
	var z_top_offset = z_offset + depth_offset * z_scale

	var trixel_faces = Dictionary()
	
	for x in layer_size_x: for y in layer_size_y:
		var pos = _trixel_layer_lookup[x*x_scale + y*y_scale + z_offset]
		if pos and not (has_top and _trixel_layer_lookup[x*x_scale + y*y_scale + z_top_offset]):
			trixel_faces[pos] = true
		
	return trixel_faces

func _generate_trixel_layers_lookup():
	var bounds = _trixels.trixel_bounds
	
	_trixel_layer_lookup = []
	_trixel_layer_lookup.resize(_trixels.trixels_count)
	
	var y_scale = bounds.x
	var z_scale = bounds.x * bounds.y
	
	for pos in _trixels.data:
		_trixel_layer_lookup[pos.x + pos.y*y_scale + pos.z*z_scale] = pos


func _add_plane_to_mesh(mesh_arrays : Array, plane : Dictionary):
	var face_normal = TrixelContainer.get_face_normal(plane.face)
	var dir_x = TrixelContainer.get_face_tangent(plane.face).abs()
	var dir_y = TrixelContainer.get_face_cotangent(plane.face).abs()
	
	var pos = plane.position as Vector3
	
	var face_corner = pos + (Vector3i.ONE + face_normal - (dir_x + dir_y)) * 0.5
	var face_offset_x = (dir_x * plane.size.x) as Vector3
	var face_offset_y = (dir_y * plane.size.y) as Vector3
	
	var face_vertices = [
		face_corner,
		face_corner + face_offset_x,
		face_corner + face_offset_x + face_offset_y,
		face_corner + face_offset_y
	]
	
	var uvs = []
	for i in 4: uvs.push_back(TrixelCubemap.trixel_coords_to_uv(
		face_vertices[i], plane.face, _trixels.trixel_bounds
	))
	
	# this check is a result of using abs on tangent vectors
	const indices_clockwise = [2,1,0,0,3,2]
	const indices_counter_clockwise = [0,1,2,2,3,0]
	
	var use_clockwise = face_normal.x < 0 or face_normal.y < 0 or face_normal.z > 0
	var indices = indices_clockwise if use_clockwise else indices_counter_clockwise
	
	for i in indices:
		mesh_arrays[Mesh.ARRAY_VERTEX].push_back(face_vertices[i])
		mesh_arrays[Mesh.ARRAY_NORMAL].push_back(face_normal)
		mesh_arrays[Mesh.ARRAY_TEX_UV].push_back(uvs[i])


func materialize(trixels : TrixelContainer):
	_trixels = trixels
	_generate_mesh()
	
	scale = Vector3.ONE / _trixels.trixels_per_trile
	position = _trixels.trile_size * -0.5
