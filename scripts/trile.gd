class_name Trile extends Resource

enum Face {FRONT, BACK, TOP, BOTTOM, LEFT, RIGHT}

const DEFAULT_RESOLUTION = 16
const DEFAULT_SIZE = Vector3i.ONE

var resolution : int # how many trixels within a trile unit
var size : Vector3i # the size of a trile, in units
var trixel_bounds : Vector3i # the size of a trile, in trixels
var trixels_count : int # the number of triles stored in this trile

var y_index : int
var z_index : int

var buffer : PackedByteArray

func _initialize_data_buffer():
	buffer = PackedByteArray()
	buffer.resize(trixels_count)

func _recalculate_constants():
	trixel_bounds = size * resolution
	trixels_count = trixel_bounds.x * trixel_bounds.y * trixel_bounds.z
	y_index = trixel_bounds.x
	z_index = trixel_bounds.x * trixel_bounds.y

func get_trixel_width_along_axis(axis : Vector3i) -> int:
	var axis_size := trixel_bounds * axis
	return abs(axis_size.x + axis_size.y + axis_size.z)

func contains_trixel_pos(pos : Vector3i) -> bool:
	return pos.x >= 0 and pos.x < trixel_bounds.x \
	and pos.y >= 0 and pos.y < trixel_bounds.y \
	and pos.z >= 0 and pos.z < trixel_bounds.z

func get_trixel(pos : Vector3i) -> bool:
	if not contains_trixel_pos(pos): return false
	else: return buffer[pos.x + pos.y*y_index + pos.z*z_index]
	
func get_adjacent_trixel(pos : Vector3i, face : Face) -> bool:
	return get_trixel(pos + Trile.get_face_normal(face))

func is_trixel_face_solid(pos : Vector3i, face : Face) -> bool:
	return get_trixel(pos) and not get_trixel(pos + Trile.get_face_normal(face))

func set_trixel(pos : Vector3i, state : bool):
	if pos.x >= 0 and pos.x < trixel_bounds.x \
	and pos.y >= 0 and pos.y < trixel_bounds.y \
	and pos.z >= 0 and pos.z < trixel_bounds.z :
		buffer[pos.x + pos.y*y_index + pos.z*z_index] = 1 if state else 0
	
func set_trixels(positions : Array, state : bool):
	for pos in positions:
		if pos.x >= 0 and pos.x < trixel_bounds.x \
		and pos.y >= 0 and pos.y < trixel_bounds.y \
		and pos.z >= 0 and pos.z < trixel_bounds.z :
			buffer[pos.x + pos.y*y_index + pos.z*z_index] = 1 if state else 0

func fill_trixels(mins : Vector3i, maxs : Vector3i, state : bool):
	var range_x = range(maxi(mins.x, 0), mini(maxs.x+1, trixel_bounds.x))
	var range_y = range(maxi(mins.y, 0), mini(maxs.y+1, trixel_bounds.y))
	var range_z = range(maxi(mins.z, 0), mini(maxs.z+1, trixel_bounds.z))
	for x in range_x: for y in range_y: for z in range_z:
		buffer[x + y*y_index + z*z_index] = 1 if state else 0

func initialize_trile(
	trile_size : Vector3i = DEFAULT_SIZE, 
	trile_resolution : int = DEFAULT_RESOLUTION
):
	size = trile_size
	resolution = trile_resolution
	_recalculate_constants()
	_initialize_data_buffer()

func trixel_to_local(trixel_pos : Vector3) -> Vector3:
	return (trixel_pos / resolution) - (size as Vector3) / 2.0

func local_to_trixel(local_pos : Vector3) -> Vector3:
	return (local_pos + (size as Vector3) / 2.0) * resolution


static func get_face_normal(face : Face) -> Vector3i:
	const normal_lookup := [
		Vector3i.BACK,    # Face.FRONT
		Vector3i.FORWARD, # Face.BACK
		Vector3i.UP,      # Face.TOP
		Vector3i.DOWN,    # Face.BOTTOM
		Vector3i.LEFT,    # Face.LEFT
		Vector3i.RIGHT,   # Face.RIGHT
	]
	return normal_lookup[face]

static func get_face_tangent(face : Face) -> Vector3i:
	const tangent_lookup := [
		Vector3i.UP,      # Face.FRONT
		Vector3i.UP,      # Face.BACK
		Vector3i.RIGHT,   # Face.TOP
		Vector3i.RIGHT,   # Face.BOTTOM
		Vector3i.BACK,    # Face.LEFT
		Vector3i.BACK,    # Face.RIGHT
	]
	return tangent_lookup[face]
	
static func get_face_cotangent(face : Face) -> Vector3i:
	const cotangent_lookup := [
		Vector3i.RIGHT,   # Face.FRONT
		Vector3i.RIGHT,   # Face.BACK
		Vector3i.BACK,    # Face.TOP
		Vector3i.BACK,    # Face.BOTTOM
		Vector3i.UP,      # Face.LEFT
		Vector3i.UP,      # Face.RIGHT
	]
	return cotangent_lookup[face]

static func face_from_normal(vec : Vector3i) -> Face:
	const face_lookup := [
		Face.BACK,
		Face.BOTTOM,
		Face.LEFT,
		0,
		Face.RIGHT,
		Face.TOP,
		Face.FRONT,
	]
	var face_index = vec.x + vec.y * 2 + vec.z * 3 + 3
	if face_index >= 0 and face_index <= 6: 
		return face_lookup[face_index]
	else: return Face.TOP
