class_name TrixelCubemap extends ImageTexture


static func trixel_coords_to_uv(
	coords : Vector3i, 
	face : TrixelContainer.Face,
	trixel_bounds : Vector3i
):
	const texture_offset_lookup = [0, 2, 4, 5, 3, 1]
	var texture_offset = texture_offset_lookup[face]
	
	var texture_plane_pos = (coords as Vector3) / (trixel_bounds as Vector3) - Vector3.ONE * 0.5
	var tangent = TrixelContainer.get_face_tangent(face) as Vector3
	var cotangent = TrixelContainer.get_face_cotangent(face) as Vector3
	
	return Vector2(
		(texture_plane_pos.dot(tangent) + 0.5 + texture_offset) / 6.0,
		texture_plane_pos.dot(cotangent) + 0.5
	)
