class_name TrixelMaterializer extends MeshInstance3D

var _trixels : TrixelContainer


var _visited = []
func _reload_visited_cache():
	_visited.resize(_trixels.get_trixels_count())
	_visited.fill(false)
	
func _has_visited(pos : Vector3i):
	if not _trixels.is_within_bounds(pos): return true
	return _visited[_trixels.get_trixel_index(pos)]

func _mark_face_visited(
	dir_x : Vector3i, dir_y : Vector3i, 
	pos : Vector3i, face: Vector2i
):
	for face_x in range(face.x): for face_y in range(face.y):
		var trixel_pos = pos + dir_x * face_x + dir_y * face_y
		if not _trixels.is_within_bounds(trixel_pos): continue
		_visited[_trixels.get_trixel_index(trixel_pos)] = true


func _generate_mesh():
	
	var mesh_arrays = []
	mesh_arrays.resize(Mesh.ARRAY_MAX)
	mesh_arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array()
	mesh_arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array()
	mesh_arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array()
	for i in range(6): _generate_side(i, mesh_arrays)
	
	mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arrays)


func _generate_side(face : TrixelContainer.Face, mesh_arrays : Array):
	var dir_x = TrixelContainer.get_face_tangent(face).abs()
	var dir_y = TrixelContainer.get_face_cotangent(face).abs()
	
	_reload_visited_cache()
	
	var bounds = _trixels.get_trixel_bounds()
	for x in range(bounds.x): for y in range(bounds.y): for z in range(bounds.z):
		var pos = Vector3i(x,y,z)
		if not _is_unvisited_solid_face(pos, face): continue
		
		var face_x = _greedy_face_search(pos, face, dir_y, dir_x, 1)
		var face_y = _greedy_face_search(pos, face, dir_x, dir_y, face_x)
		
		var face_size = Vector2i(face_x, face_y)
		
		_mark_face_visited(dir_x, dir_y, pos, face_size)
		_add_face_to_mesh(pos, face_size, dir_x, dir_y, face, mesh_arrays)

func _is_unvisited_solid_face(pos : Vector3i, face : TrixelContainer.Face) -> bool:
	if _trixels.get_trixel(pos) == false: return false
	if _has_visited(pos): return false
	if _trixels.get_adjacent_trixel(pos, face) == true: return false
	return true

func _greedy_face_search(
	pos : Vector3i, face : TrixelContainer.Face,
	dir_width : Vector3i, dir_search : Vector3i,
	width: int,
) -> int:
	var search_steps_limit = _trixels.get_trixels_count()
	var search_len = 1
	while search_len <= search_steps_limit:
		for check_x in range(width):
			var check_pos = pos + dir_width * check_x + dir_search * search_len
			if not _is_unvisited_solid_face(check_pos, face): return search_len
		search_len += 1
	return search_len


func _add_face_to_mesh(
	pos : Vector3i, face_size: Vector2i, 
	dir_x : Vector3i, dir_y : Vector3i, 
	face : TrixelContainer.Face,
	mesh_arrays : Array
):
	var face_normal = TrixelContainer.get_face_normal(face)
	
	var face_corner = pos as Vector3 + (Vector3i.ONE + face_normal - (dir_x + dir_y)) * 0.5
	var face_offset_x = (dir_x * face_size.x) as Vector3
	var face_offset_y = (dir_y * face_size.y) as Vector3
	
	var face_vertices = [
		face_corner,
		face_corner + face_offset_x,
		face_corner + face_offset_x + face_offset_y,
		face_corner + face_offset_y
	]
	
	var uvs = []
	for i in range(4): uvs.push_back(TrixelCubemap.trixel_coords_to_uv(
		face_vertices[i], face, _trixels.get_trixel_bounds()
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
	
	scale = Vector3.ONE / _trixels.get_trixels_per_trile()
	position = _trixels.get_trile_size() * -0.5
