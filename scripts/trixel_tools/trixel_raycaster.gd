class_name TrixelRaycaster

class Result:
	var hit_trixel : bool
	var hit_wall : bool
	var face : int
	var position : Vector3i

static func cast_in_trile_space(trile : Trile, start : Vector3, dir : Vector3) -> Result:
	const BUMP_EPSILON := 0.001
	
	var result := Result.new()
	
	var bounds_hit = try_hit_trixel_bounds(trile, start, dir)
	if bounds_hit == null: return null
	var bounds_hit_pos : Vector3 = bounds_hit
	var started_in_trile := start == bounds_hit_pos
	
	var current_position := bounds_hit_pos
	var current_trixelpos := (bounds_hit_pos - dir * BUMP_EPSILON).floor() as Vector3i
	var last_trixelpos := current_trixelpos
	var did_hit_trixel := false
	var did_hit_wall := false
	var first_step := true
	
	while not (did_hit_trixel or did_hit_wall):
		# to make sure we're calculating within the trixel:
		var bumped_position := current_position + dir * BUMP_EPSILON
		
		var next_trixel_distances := (-bumped_position * dir.sign()).posmod(1.0)
		var all_magnitudes_to_next_trixel := next_trixel_distances / dir.abs()
		
		var magnitude_to_next_trixel := all_magnitudes_to_next_trixel[
			all_magnitudes_to_next_trixel.min_axis_index()
		]
		
		last_trixelpos = current_trixelpos
		current_trixelpos = bumped_position.floor() as Vector3i
		
		if not first_step and current_trixelpos == last_trixelpos:
			push_error("TrixelRaycaster stuck in a trixel.")
			return null
		
		if not trile.contains_trixel_pos(current_trixelpos):
			did_hit_wall = true
		elif trile.get_trixel(current_trixelpos):
			if first_step and started_in_trile: return null
			else: did_hit_trixel = true
		
		current_position = bumped_position + dir * magnitude_to_next_trixel
		first_step = false
	
	result.hit_trixel = did_hit_trixel
	result.hit_wall = did_hit_wall
	result.face = Trile.face_from_normal(last_trixelpos - current_trixelpos)
	result.position = current_trixelpos
	
	return result


static func try_hit_trixel_bounds(
	trile : Trile, start : Vector3, dir : Vector3
):
	var size := trile.get_trixel_bounds() as Vector3
	var trile_aabb := AABB(Vector3.ZERO, size)
	return trile_aabb.intersects_segment(start, start + dir * 1000)
