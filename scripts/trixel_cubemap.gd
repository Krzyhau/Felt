class_name TrixelCubemap extends ImageTexture

static func trixel_coords_to_uv(
	coords : Vector3, 
	face : TrixelContainer.Face,
	trile_size : Vector3i
) -> Vector2:
	var texture_offset_x = TrixelCubemap.get_face_texture_x_offset(face)
	
	var face_normal = TrixelContainer.get_face_normal(face) as Vector3
	
	var trixel_scaled_position = (coords as Vector3) / (trile_size as Vector3)
	var texture_plane_pos = (Vector3.ONE - abs(face_normal)) * trixel_scaled_position + (face_normal + Vector3.ONE) * 0.5
	var tangent = TrixelCubemap.get_face_texture_tangent(face)
	var cotangent = TrixelCubemap.get_face_texture_cotangent(face)
	
	var x_coord = tangent.dot(texture_plane_pos)
	var y_coord = cotangent.dot(texture_plane_pos)
	
	if face != TrixelContainer.Face.TOP:
		y_coord = 1.0 - y_coord
	
	return Vector2((x_coord + texture_offset_x) / 6.0, y_coord)

static func get_face_texture_x_offset(face : TrixelContainer.Face) -> int:
	const offset_lookup := [
		0,  # Face.FRONT
		3,  # Face.BACK
		4,  # Face.TOP
		5,  # Face.BOTTOM
		3,  # Face.LEFT
		2,  # Face.RIGHT
	]
	return offset_lookup[face]

static func get_face_texture_tangent(face : TrixelContainer.Face) -> Vector3:
	const tangent_lookup := [
		Vector3.RIGHT,   # Face.FRONT
		Vector3.LEFT,    # Face.BACK
		Vector3.RIGHT,   # Face.TOP
		Vector3.RIGHT,   # Face.BOTTOM
		Vector3.BACK,    # Face.LEFT
		Vector3.FORWARD, # Face.RIGHT
	]
	return tangent_lookup[face]
	
static func get_face_texture_cotangent(face : TrixelContainer.Face) -> Vector3:
	const cotangent_lookup := [
		Vector3.UP,   # Face.FRONT
		Vector3.UP,   # Face.BACK
		Vector3.BACK, # Face.TOP
		Vector3.BACK, # Face.BOTTOM
		Vector3.UP,   # Face.LEFT
		Vector3.UP,   # Face.RIGHT
	]
	return cotangent_lookup[face]
