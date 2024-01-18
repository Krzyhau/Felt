class_name TrixelRaycaster


static func cast(trixels : TrixelContainer, start : Vector3, dir : Vector3):
	var cast_result = {
		hit_trixel = false,
		face = TrixelContainer.Face.TOP,
		pos = Vector3i(0,0,0),
	}
	
	var bounds_hit = try_hit_trixel_bounds(trixels, start, dir)
	if bounds_hit == null: return null
	
	var x_dir = Vector3.RIGHT * sign(dir.x)
	var y_dir = Vector3.UP * sign(dir.y)
	var z_dir = Vector3.BACK * sign(dir.z)
	
	var curr_pos = bounds_hit
	
	var bounds = trixels.trixel_bounds
	var max_iterations = bounds.x + bounds.y + bounds.z + 3
	
	for i in max_iterations:
		var bumped_curr_pos = curr_pos + dir * 0.001
		
		var proj = Vector3(
			bumped_curr_pos.dot(x_dir),
			bumped_curr_pos.dot(y_dir),
			bumped_curr_pos.dot(z_dir)
		)
		var pad = Vector3.ONE - (-proj).posmod(1.0)
		var x_dist = INF if dir.x == 0 else pad.x / abs(dir.x)
		var y_dist = INF if dir.y == 0 else pad.y / abs(dir.y)
		var z_dist = INF if dir.z == 0 else pad.z / abs(dir.z)
		
		var step = min(x_dist, y_dist, z_dist)
		
		if step == 0:
			push_error("TrixelRaycaster attempted to trace ray with step 0")
			return null
		
		var trixelpos = floor(bumped_curr_pos) as Vector3i
		
		var hit_wall = not trixels.is_within_bounds(trixelpos)
		
		if hit_wall:
			cast_result.hit_trixel = true
			cast_result.pos = trixelpos
			
			if trixelpos.x < 0: cast_result.face = TrixelContainer.Face.LEFT
			elif trixelpos.y < 0: cast_result.face = TrixelContainer.Face.BOTTOM
			elif trixelpos.z < 0: cast_result.face = TrixelContainer.Face.FRONT
			elif trixelpos.x >= bounds.x: cast_result.face = TrixelContainer.Face.RIGHT
			elif trixelpos.y >= bounds.y: cast_result.face = TrixelContainer.Face.TOP
			elif trixelpos.z >= bounds.z: cast_result.face = TrixelContainer.Face.BACK
			
			return cast_result
		
		var trixel_index = trixelpos.x + trixelpos.y*trixels.y_index + trixelpos.z*trixels.z_index
		var trixel_state = trixels.buffer[trixel_index]
		if trixel_state:
			cast_result.hit_trixel = true
			cast_result.pos = trixelpos
			
			var max_pad = max(pad.x, pad.y, pad.z)
			if max_pad == pad.x:
				if dir.x > 0: cast_result.face = TrixelContainer.Face.LEFT
				else: cast_result.face = TrixelContainer.Face.RIGHT
			elif max_pad == pad.y:
				if dir.y > 0: cast_result.face = TrixelContainer.Face.BOTTOM
				else: cast_result.face = TrixelContainer.Face.TOP
			elif max_pad == pad.z:
				if dir.z > 0: cast_result.face = TrixelContainer.Face.FRONT
				else: cast_result.face = TrixelContainer.Face.BACK
			
			return 
		
		curr_pos = bumped_curr_pos + dir * step
	
	return cast_result


static func try_hit_trixel_bounds(
	trixels : TrixelContainer, start : Vector3, dir : Vector3
):
	var trixel_bounds = trixels.trixel_bounds
	var trixel_raycheck_bounds = AABB(trixel_bounds as Vector3 * 0.5, trixel_bounds)
	return trixel_raycheck_bounds.intersects_ray(start, dir)
