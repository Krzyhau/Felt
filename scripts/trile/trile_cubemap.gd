class_name TrileCubemap extends ImageTexture

var _trile : Trile
var _texture_resulution: int

var buffer_image : Image

func _init(trile : Trile):
	_trile = trile
	_generate_image()

func _generate_image():
	var max_dimension := _trile.size[_trile.size.max_axis_index()]
	_texture_resulution = (max_dimension * _trile.resolution) as int
	var width := _texture_resulution * 6
	var height := _texture_resulution
	buffer_image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	buffer_image.fill(Color(1.0, 1.0, 1.0, 0.0))
	set_image(buffer_image)

func _fill_trixel_face(position : Vector3i, face : Trile.Face, color : Color):
	var pixel_pos := trixel_coords_to_texture_coords(position, face)
	if buffer_image.get_pixelv(pixel_pos) == color: return
	
	var texture_tangent = Trile.get_face_tangent(face) as Vector3i
	var texture_cotangent = Trile.get_face_cotangent(face) as Vector3i
	var endpos = position + texture_tangent + texture_cotangent
	
	
	var pixel_endpos := trixel_coords_to_texture_coords(endpos, face)
	
	var pixel_dir = (pixel_endpos - pixel_pos).sign()
	
	for x in range(pixel_pos.x, pixel_endpos.x, pixel_dir.x):
		for y in range(pixel_pos.y, pixel_endpos.y, pixel_dir.y):
			buffer_image.set_pixel(x, y, color)


func apply_external_image(img : Image):
	set_image(img)
	buffer_image = img

func paint(position : Vector3i, face : Trile.Face, color : Color):
	_fill_trixel_face(position, face, color)
	set_image(buffer_image)

func fill(position : Vector3i, face : Trile.Face, color : Color):
	var existing_color = pick_color(position, face)
	if color == existing_color: return
	
	var triles_to_fill := Dictionary()
	var propagation_triles := Dictionary()
	
	var tangent_vector := Trile.get_face_tangent(face)
	var cotangent_vector := Trile.get_face_cotangent(face)
	
	propagation_triles[position] = true
	
	while propagation_triles.keys().size() > 0:
		for pos in propagation_triles.keys():
			triles_to_fill[pos] = true
		
		var new_propagation_triles := Dictionary()
		
		for pos in propagation_triles.keys():
			for newpos in [
				pos - tangent_vector,
				pos + tangent_vector,
				pos - cotangent_vector,
				pos + cotangent_vector
			]:
				if (
					triles_to_fill.has(newpos) or 
					new_propagation_triles.has(newpos) or
					not _trile.is_trixel_face_solid(newpos, face) or
					pick_color(newpos, face) != existing_color
				): continue
				
				new_propagation_triles[newpos] = true
		
		propagation_triles = new_propagation_triles
	
	for pos in triles_to_fill.keys():
		_fill_trixel_face(pos, face, color)
		
	set_image(buffer_image)

func pick_color(position : Vector3i, face : Trile.Face) -> Color:
	var pixel_pos := trixel_coords_to_texture_coords(position, face)
	return buffer_image.get_pixelv(pixel_pos)

func trixel_coords_to_texture_coords(coords : Vector3i, face : Trile.Face) -> Vector2i:
	var texture_based_offset = Vector3.ONE * (0.5 / _trile.resolution)
	texture_based_offset *= _trile.size * (_trile.resolution / (_texture_resulution as float))
	var trixel_local_mid_pos = _trile.trixel_to_local(coords) + texture_based_offset
	var uv_coords := trile_coords_to_uv(trixel_local_mid_pos, face)
	var texture_pos := uv_coords * (buffer_image.get_size() as Vector2)
	var pixel_pos := texture_pos.floor() as Vector2i
	return pixel_pos

func trile_coords_to_uv(coords : Vector3, face : Trile.Face) -> Vector2:
	var texture_offset_x := TrileCubemap.get_face_texture_x_offset(face)
	
	var face_normal := Trile.get_face_normal(face) as Vector3
	
	var trixel_scaled_position := (coords as Vector3) / (_trile.size as Vector3)
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
