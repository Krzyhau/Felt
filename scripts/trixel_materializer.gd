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
	var vertices = PackedVector3Array()
	for i in range(6): _generate_side(i, vertices)
	
	var array_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = array_mesh
	
	print(len(vertices))

func _generate_side(face : TrixelContainer.Face, vertices : PackedVector3Array):
	var dir_x = _trixels.get_face_tangent(face).abs()
	var dir_y = _trixels.get_face_cotangent(face).abs()
	var face_normal = _trixels.get_face_normal(face)
	
	_reload_visited_cache()
	
	var bounds = _trixels.get_trixel_bounds()
	for x in range(bounds.x): for y in range(bounds.y): for z in range(bounds.z):
		var pos = Vector3i(x,y,z)
		if not _is_unvisited_solid_face(pos, face): continue
		
		var face_size : Vector2i
		
		face_size.x = _greedy_face_search(pos, face, dir_y, dir_x, 1)
		face_size.y = _greedy_face_search(pos, face, dir_x, dir_y, face_size.x)
		
		_mark_face_visited(dir_x, dir_y, pos, face_size)
		_add_face_to_mesh(pos, face_size, dir_x, dir_y, face_normal, vertices)

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
	face_normal : Vector3i,
	vertices : PackedVector3Array
):
	var face_corner = pos as Vector3 + (Vector3i.ONE + face_normal - (dir_x + dir_y)) * 0.5
	var face_offset_x = (dir_x * face_size.x) as Vector3
	var face_offset_y = (dir_y * face_size.y) as Vector3
	
	var face_vertices = [
		face_corner,
		face_corner + face_offset_x,
		face_corner + face_offset_x + face_offset_y,
		face_corner + face_offset_y
	]
	
	if face_normal.x < 0 or face_normal.y < 0 or face_normal.z > 0:
		for i in [2,1,0,0,3,2]: vertices.push_back(face_vertices[i])
	else:
		for i in [0,1,2,2,3,0]: vertices.push_back(face_vertices[i])


func materialize(trixels : TrixelContainer):
	_trixels = trixels
	_generate_mesh()
	
	scale = Vector3.ONE / _trixels.get_trixels_per_trile()
	position = _trixels.get_trile_size() * -0.5
