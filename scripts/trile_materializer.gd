class_name TrileMaterializer extends Resource

signal materialized(trile : Trile, mesh_data : Array, interrupted : bool)

var _generation_thread : Thread
var _generation_mutex : Mutex = Mutex.new()
var _generation_stopped: bool = false
var _mesh_data : Array

var _trile : Trile

func _init(trile : Trile):
	_trile = trile

func materialize():
	interrupt_if_active()
	
	_generation_stopped = false
	_generation_thread = Thread.new()
	_generation_thread.start(_generate_mesh)

func interrupt_if_active():
	if _generation_thread:
		_generation_mutex.lock()
		_generation_stopped = true
		_generation_mutex.unlock()
		_generation_thread.wait_to_finish()

func is_materializing() -> bool:
	return _generation_thread and _generation_thread.is_alive()
	
func _should_stop() -> bool:
	_generation_mutex.lock()
	var should_stop := _generation_stopped
	_generation_mutex.unlock()
	return should_stop



func _generate_mesh():
	var gen_start_time = Time.get_ticks_usec()
	
	_mesh_data = []
	_mesh_data.resize(Mesh.ARRAY_MAX)
	_mesh_data[Mesh.ARRAY_VERTEX] = PackedVector3Array()
	_mesh_data[Mesh.ARRAY_TEX_UV] = PackedVector2Array()
	
	_generate_mesh_data(_mesh_data)
	var interrupted = _should_stop()
	
	var gen_end_time = Time.get_ticks_usec()
	var gen_time = (gen_end_time-gen_start_time)/1000.0
	var gen_time_str = "interrupted" if interrupted else ("%.3f ms" % gen_time)
	if interrupted: gen_time_str = "interrupted"
	
	print("_generate_mesh() - %s" % gen_time_str)
	call_deferred("_on_materialized", interrupted)

func _on_materialized(interrupted : bool):
	materialized.emit(_trile, _mesh_data, interrupted)

func _generate_mesh_data(mesh_arrays : Array):
	for face in 6:
		var layer_dir = Trile.get_face_normal(face).abs()
		var layer_dir_depth = _trile.get_trixel_width_along_axis(layer_dir)
		
		for layer in layer_dir_depth:
			var trixel_faces := _get_trixel_faces_map(face, layer)
			var planes = _find_planes_in_layer(face, trixel_faces)
			for plane in planes: 
				_add_plane_to_mesh(mesh_arrays, plane.position, plane.size, face)

			if _should_stop(): return

# performs a greedy search on a 2D slice of a trile art to find rectangular planes
# returns an array of planes, where each plane stores 3D position of its corner and size
func _find_planes_in_layer(face : Trile.Face, trixel_faces : Dictionary) -> Array:
	var dir_x := Trile.get_face_tangent(face).abs()
	var dir_y := Trile.get_face_cotangent(face).abs()

	var layer_size_x := _trile.get_trixel_width_along_axis(dir_x)
	var layer_size_y := _trile.get_trixel_width_along_axis(dir_y)
	
	var planes := []
	while trixel_faces.size() > 0:
		var plane_position : Vector3i = trixel_faces.keys()[0]
		trixel_faces.erase(plane_position)
		var plane_size := Vector2i(1,1)
		
		# greedy search in relative x axis
		while plane_size.x < layer_size_x:
			var face_pos := plane_position + dir_x * plane_size.x
			if trixel_faces.has(face_pos):
				trixel_faces.erase(face_pos)
				plane_size.x += 1
			else: break
		
		# greedy search in relative y axis
		while plane_size.y < layer_size_y:
			var face_pos_y := plane_position + dir_y * plane_size.y
			var valid_faces := []
			for x in plane_size.x:
				var face_pos_x := face_pos_y + dir_x * x
				if trixel_faces.has(face_pos_x):
					valid_faces.append(face_pos_x)
				else: break
			if len(valid_faces) != plane_size.x: 
				break
			for face_pos_x in valid_faces: 
				trixel_faces.erase(face_pos_x)
			plane_size.y += 1
		
		planes.append({
			position = plane_position,
			size = plane_size,
		})
	return planes

# get a map for every unobstructed trixel face in given layer
func _get_trixel_faces_map(face : Trile.Face, depth : int) -> Dictionary:
	var dir_x := Trile.get_face_tangent(face).abs()
	var dir_y := Trile.get_face_cotangent(face).abs()
	var dir_z := Trile.get_face_normal(face).abs()

	var layer_size_x := _trile.get_trixel_width_along_axis(dir_x)
	var layer_size_y := _trile.get_trixel_width_along_axis(dir_y)
	var layer_size_z := _trile.get_trixel_width_along_axis(dir_z)

	var x_index := 1 if dir_x.x else _trile.y_index if dir_x.y else _trile.z_index
	var y_index := 1 if dir_y.x else _trile.y_index if dir_y.y else _trile.z_index
	var z_index := 1 if dir_z.x else _trile.y_index if dir_z.y else _trile.z_index

	var face_normal := Trile.get_face_normal(face)
	var depth_offset := (face_normal.x + face_normal.y + face_normal.z)
	var abs_depth := depth if depth_offset > 0 else layer_size_z - 1 - depth
	var z_offset := abs_depth * z_index
	var z_top_offset := z_offset + depth_offset * z_index

	var trixel_faces := Dictionary()
	
	var buffer := _trile.buffer
	var has_top := depth + 1 < layer_size_z
	var face_z_pos := dir_z * abs_depth
	
	for x in layer_size_x: for y in layer_size_y:
		if buffer[x * x_index + y * y_index + z_offset] \
		and not (has_top and buffer[x * x_index + y * y_index + z_top_offset]):
			trixel_faces[x * dir_x + y * dir_y + face_z_pos] = true
		
	return trixel_faces


func _add_plane_to_mesh(
	mesh_arrays : Array, 
	pos : Vector3i, 
	size : Vector2i, 
	face : Trile.Face
):
	var face_normal := Trile.get_face_normal(face)
	var dir_x := Trile.get_face_tangent(face).abs()
	var dir_y := Trile.get_face_cotangent(face).abs()
	
	var face_corner := pos as Vector3 + (Vector3i.ONE + face_normal - (dir_x + dir_y)) * 0.5
	var face_offset_x := (dir_x * size.x) as Vector3
	var face_offset_y := (dir_y * size.y) as Vector3
	
	face_corner = (face_corner / _trile.resolution) - _trile.size * 0.5
	face_offset_x /= _trile.resolution
	face_offset_y /= _trile.resolution
	
	var face_vertices := [
		face_corner,
		face_corner + face_offset_x,
		face_corner + face_offset_x + face_offset_y,
		face_corner + face_offset_y
	]
	
	var uvs := []
	for i in 4: uvs.push_back(TrileCubemap.trixel_coords_to_uv(
		face_vertices[i], face, _trile.size
	))
	
	# this check is a result of using abs on tangent vectors
	const indices_clockwise := [2,1,0,0,3,2]
	const indices_counter_clockwise := [0,1,2,2,3,0]
	
	var use_clockwise := face_normal.x < 0 or face_normal.y < 0 or face_normal.z < 0
	var indices := indices_clockwise if use_clockwise else indices_counter_clockwise
	
	for i in indices:
		mesh_arrays[Mesh.ARRAY_VERTEX].push_back(face_vertices[i])
		mesh_arrays[Mesh.ARRAY_TEX_UV].push_back(uvs[i])





