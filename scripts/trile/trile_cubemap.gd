class_name TrileCubemap extends ImageTexture

var _trile : Trile

var buffer_image : Image

func _init(trile : Trile):
	_trile = trile
	_generate_image()

func _generate_image():
	var width := _trile.size_in_trixels * 6
	var height := _trile.size_in_trixels
	buffer_image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	buffer_image.fill(Color.WHITE)
	set_image(buffer_image)

func paint(position : Vector3i, face : Trile.Face, color : Color):
	var pixel_pos := trixel_coords_to_texture_coords(position, face)
	
	var existing_color = buffer_image.get_pixelv(pixel_pos)
	if color == existing_color: return
	
	buffer_image.set_pixelv(pixel_pos, color)
	set_image(buffer_image)
	
func pick_color(position : Vector3i, face : Trile.Face) -> Color:
	var pixel_pos := trixel_coords_to_texture_coords(position, face)
	return buffer_image.get_pixelv(pixel_pos)

func trixel_coords_to_texture_coords(coords : Vector3i, face : Trile.Face) -> Vector2i:
	var trixel_local_mid_pos = _trile.trixel_to_local(coords) + Vector3.ONE * (0.5 / _trile.resolution)
	var uv_coords := trile_coords_to_uv(trixel_local_mid_pos, face)
	var texture_pos := uv_coords * (buffer_image.get_size() as Vector2)
	var pixel_pos := texture_pos.floor() as Vector2i
	return pixel_pos

func trile_coords_to_uv(coords : Vector3, face : Trile.Face) -> Vector2:
	var texture_offset_x := TrileCubemap.get_face_texture_x_offset(face)
	
	var face_normal := Trile.get_face_normal(face) as Vector3
	
	var trixel_scaled_position := (coords as Vector3) / (Vector3.ONE * _trile.size)
	var texture_plane_pos := (Vector3.ONE - face_normal.abs()) * trixel_scaled_position + (face_normal + Vector3.ONE) * 0.5
	var tangent: = TrileCubemap.get_face_texture_tangent(face)
	var cotangent := TrileCubemap.get_face_texture_cotangent(face)
	
	var x_coord := tangent.dot(texture_plane_pos)
	var y_coord := cotangent.dot(texture_plane_pos)
	
	if face != Trile.Face.TOP:
		y_coord = 1.0 - y_coord
	
	return Vector2((x_coord + texture_offset_x) / 6.0, y_coord)

static func get_face_texture_x_offset(face : Trile.Face) -> int:
	const offset_lookup := [
		0,  # Face.FRONT
		3,  # Face.BACK
		4,  # Face.TOP
		5,  # Face.BOTTOM
		3,  # Face.LEFT
		2,  # Face.RIGHT
	]
	return offset_lookup[face]

static func get_face_texture_tangent(face : Trile.Face) -> Vector3:
	const tangent_lookup := [
		Vector3.RIGHT,   # Face.FRONT
		Vector3.LEFT,    # Face.BACK
		Vector3.RIGHT,   # Face.TOP
		Vector3.RIGHT,   # Face.BOTTOM
		Vector3.BACK,    # Face.LEFT
		Vector3.FORWARD, # Face.RIGHT
	]
	return tangent_lookup[face]
	
static func get_face_texture_cotangent(face : Trile.Face) -> Vector3:
	const cotangent_lookup := [
		Vector3.UP,   # Face.FRONT
		Vector3.UP,   # Face.BACK
		Vector3.BACK, # Face.TOP
		Vector3.BACK, # Face.BOTTOM
		Vector3.UP,   # Face.LEFT
		Vector3.UP,   # Face.RIGHT
	]
	return cotangent_lookup[face]
