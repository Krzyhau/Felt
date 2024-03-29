class_name TrileDematerializer extends Resource

signal dematerialized(trile : Trile, trixel_data : PackedByteArray, interrupted : bool)

var _generation_thread : Thread
var _generation_mutex : Mutex = Mutex.new()
var _generation_stopped: bool = false
var _trixel_data : PackedByteArray

var _trile : Trile

func _init(trile : Trile):
	_trile = trile

func dematerialize():
	interrupt_if_active()
	
	_generation_stopped = false
	_generation_thread = Thread.new()
	_generation_thread.start(_generate_trixel_data)

func interrupt_if_active():
	if _generation_thread:
		_generation_mutex.lock()
		_generation_stopped = true
		_generation_mutex.unlock()
		_generation_thread.wait_to_finish()

func is_dematerializing() -> bool:
	return _generation_thread and _generation_thread.is_alive()
	
func _should_stop() -> bool:
	_generation_mutex.lock()
	var should_stop := _generation_stopped
	_generation_mutex.unlock()
	return should_stop

func _generate_trixel_data():
	var gen_start_time = Time.get_ticks_usec()
	
	_rasterize_trile_mesh()
	var interrupted = _should_stop()
	
	var gen_end_time = Time.get_ticks_usec()
	var gen_time = (gen_end_time-gen_start_time)/1000.0
	var gen_time_str = "interrupted" if interrupted else ("%.3f ms" % gen_time)
	if interrupted: gen_time_str = "interrupted"
	
	print("_generate_trixel_data() - %s" % gen_time_str)
	call_deferred("_on_dematerialized", interrupted)

func _on_dematerialized(interrupted : bool):
	dematerialized.emit(_trile, _trixel_data, interrupted)

# transforms tri-mesh into voxel data by checking whether middle points
# of each voxel would be "sandwiched" between two planes along X axis
func _rasterize_trile_mesh():
	_trixel_data = PackedByteArray()
	_trixel_data.resize(_trile.trixels_count)
	
	var bounds_data = _construct_sandwich_data()
	
	var state := 0
	for i in range(_trile.trixels_count):
		if i % _trile.y_index == 0 or state == 2: state = 0
		if bounds_data[i] == 1: state = 1
		if bounds_data[i] == 2: state = 0
		if bounds_data[i] == 3: state = 2
		
		if state > 0: _trixel_data[i] = 1
	
	return _trixel_data

# returns an array defining where "sandwiching" begins and ends in voxel data
# 0 means state is preserved, 1 means sandwiching starts, 2 means it ends,
# 3 means it both starts and ends within the same voxel
func _construct_sandwich_data() -> PackedByteArray:
	var bounds_data := PackedByteArray()
	bounds_data.resize(_trile.trixels_count)
	
	var mesh_arrays := _trile.surface_get_arrays(0)
	var mesh_vertices : PackedVector3Array = mesh_arrays[Mesh.ARRAY_VERTEX]
	var mesh_normals : PackedVector3Array = mesh_arrays[Mesh.ARRAY_NORMAL]
	
	var trile_offset := _trile.size * 0.5
	
	for i in range(0, mesh_vertices.size(), 3):
		var x_normal := signf(mesh_normals[i].x + mesh_normals[i+1].x + mesh_normals[i+2].x)
		if x_normal == 0.0: continue
		
		var v1 := (mesh_vertices[i + 0] + trile_offset) * _trile.resolution
		var v2 := (mesh_vertices[i + 1] + trile_offset) * _trile.resolution
		var v3 := (mesh_vertices[i + 2] + trile_offset) * _trile.resolution
		
		var plane_normal := (v2-v1).normalized().cross((v3-v1).normalized()).normalized()
		var plane_d := plane_normal.dot(v1)
		if plane_normal.x == 0.0: continue
		
		var pv1 := Vector2(v1.y, v1.z)
		var pv2 := Vector2(v2.y, v2.z)
		var pv3 := Vector2(v3.y, v3.z)
		
		var line1 := Vector2(pv2.y - pv1.y, pv1.x - pv2.x).normalized()
		var d1 := line1.dot(pv1)
		var s1 := signf(d1 - line1.dot(pv3))
		d1 += s1 * 0.05
		
		var line2 := Vector2(pv3.y - pv2.y, pv2.x - pv3.x).normalized()
		var d2 := line2.dot(pv2)
		var s2 := signf(d2 - line2.dot(pv1))
		d2 += s2 * 0.05
		
		var line3 := Vector2(pv1.y - pv3.y, pv3.x - pv1.x).normalized()
		var d3 := line3.dot(pv3)
		var s3 := signf(d3 - line3.dot(pv2))
		d3 += s3 * 0.05
		
		var min_x := clampi(floorf(minf(minf(pv1.x, pv2.x), pv3.x)), 0, _trile.z_index - 1)
		var min_y := clampi(floorf(minf(minf(pv1.y, pv2.y), pv3.y)), 0, _trile.trixels_count - 1)
		var max_x := clampi(ceilf(maxf(maxf(pv1.x, pv2.x), pv3.x)), 0, _trile.z_index - 1)
		var max_y := clampi(ceilf(maxf(maxf(pv1.y, pv2.y), pv3.y)), 0, _trile.trixels_count - 1)
		
		for x in range(min_x, max_x): for y in range(min_y, max_y):
			var point := Vector2(x + 0.5, y + 0.5)
			
			# check if point is within the triangle
			if s1 != signf(d1 - line1.dot(point)): continue
			if s2 != signf(d2 - line2.dot(point)): continue
			if s3 != signf(d3 - line3.dot(point)): continue
			
			# within triangle - calculate depth from plane formula
			var depth := roundf((plane_d - point.x * plane_normal.y - point.y * plane_normal.z) / plane_normal.x)
			if depth >= _trile.y_index: continue
			
			depth = clampi(depth, 0, _trile.y_index - 1)
			
			var index := depth + x * _trile.y_index + y * _trile.z_index 
			var curr_state := bounds_data[index]
			var new_state := 1 if plane_normal.x > 0.0 else 2
			if curr_state != 0 and curr_state != new_state: new_state = 3
			bounds_data[index] = new_state
	
	return bounds_data
