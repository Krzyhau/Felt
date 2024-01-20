class_name TrixelRaycaster

static func cast(trile : Trile, start : Vector3, dir : Vector3):
	var cast_result := {
		hit_trixel = false,
		face = Trile.Face.TOP,
		position = Vector3i(0,0,0),
	}
	
	var bounds_hit = try_hit_trile_bounds(trile, start, dir)
	if bounds_hit == null: return null
	var bounds_hit_pos : Vector3 = bounds_hit
	
	var bounds := trile.trixel_bounds
	var max_iterations := bounds.x + bounds.y + bounds.z + 3
	var current_position := bounds_hit_pos
	for i in max_iterations:
		var bumped_position := current_position + dir * 0.001
		
		var next_trixel_distances := (-bumped_position * dir.sign()).posmod(1.0)
		var all_magnitudes_to_next_trixel := next_trixel_distances / dir.abs()
		
		var magnitude_to_next_trixel := all_magnitudes_to_next_trixel[
			all_magnitudes_to_next_trixel.min_axis_index()
		]
		if magnitude_to_next_trixel == 0:
			push_error("TrixelRaycaster tried to cast ray with magnitude 0")
			return null
		
		var trixelpos := floor(bumped_position) as Vector3i
		var hit_wall := not trile.contains_trixel_pos(trixelpos)
		
		if hit_wall:
			cast_result.hit_trixel = true
			cast_result.position = trixelpos
			
			if trixelpos.x < 0: cast_result.face = Trile.Face.RIGHT
			elif trixelpos.y < 0: cast_result.face = Trile.Face.TOP
			elif trixelpos.z < 0: cast_result.face = Trile.Face.FRONT
			elif trixelpos.x >= bounds.x: cast_result.face = Trile.Face.LEFT
			elif trixelpos.y >= bounds.y: cast_result.face = Trile.Face.BOTTOM
			elif trixelpos.z >= bounds.z: cast_result.face = Trile.Face.BACK
			
			return cast_result
		
		var trixel_index := trixelpos.x + trixelpos.y*trile.y_index + trixelpos.z*trile.z_index
		var trixel_state := trile.buffer[trixel_index]
		if trixel_state:
			cast_result.hit_trixel = true
			cast_result.position = trixelpos
			
			var furthest_wall_index := next_trixel_distances.max_axis_index()
			if furthest_wall_index == Vector3.AXIS_X:
				if dir.x > 0: cast_result.face = Trile.Face.LEFT
				else: cast_result.face = Trile.Face.RIGHT
			elif furthest_wall_index == Vector3.AXIS_Y:
				if dir.y > 0: cast_result.face = Trile.Face.BOTTOM
				else: cast_result.face = Trile.Face.TOP
			elif furthest_wall_index == Vector3.AXIS_Z:
				if dir.z > 0: cast_result.face = Trile.Face.BACK
				else: cast_result.face = Trile.Face.FRONT
			
			return cast_result
		
		current_position = bumped_position + dir * magnitude_to_next_trixel
	
	return cast_result


static func try_hit_trile_bounds(
	trile : Trile, start : Vector3, dir : Vector3
):
	const arbitrarily_large_number := 1000000.0
	dir = dir.normalized()
	var end := start + dir * arbitrarily_large_number
	
	var largest_entry_dist := 0.0
	var smallest_exit_dist := INF
	
	for face in 6:
		var plane_normal := Trile.get_face_normal(face) as Vector3
		var plane_dist_vec := plane_normal * (trile.trixel_bounds as Vector3)
		var plane_dist := maxf(0.0, plane_dist_vec.x + plane_dist_vec.y + plane_dist_vec.z)
		
		var start_dist = plane_normal.dot(start) - plane_dist
		var end_dist = plane_normal.dot(end) - plane_dist
		
		if start_dist > 0 and end_dist > 0: return null
		elif start_dist < 0 and end_dist < 0: continue
		
		var factor = start_dist / (start_dist - end_dist)
		
		if start_dist > 0: largest_entry_dist = max(largest_entry_dist, factor)
		if start_dist < 0: smallest_exit_dist = min(smallest_exit_dist, factor)
	
	if largest_entry_dist > smallest_exit_dist:
		return null
	
	return start + dir * arbitrarily_large_number * largest_entry_dist
