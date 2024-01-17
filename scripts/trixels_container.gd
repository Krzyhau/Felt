class_name TrixelContainer extends Resource

const DEFAULT_TRIXELS_PER_TRILE = 16
const DEFAULT_TRILE_SIZE = Vector3i.ONE

var trixels_per_trile : int
var trile_size : Vector3i
var trixel_bounds : Vector3i
var trixels_count : int

var data : Dictionary

func initialize_data_buffer():
	data = Dictionary()

func _recalculate_constants():
	trixel_bounds = trile_size * trixels_per_trile
	trixels_count = trixel_bounds.x * trixel_bounds.y * trixel_bounds.z

func get_trixel_width_along_axis(axis : Vector3i) -> int:
	var axis_size = trixel_bounds * axis
	return abs(axis_size.x + axis_size.y + axis_size.z)

func is_within_bounds(pos : Vector3i) -> bool:
	return pos.x >= 0 and pos.x < trixel_bounds.x \
	and pos.y >= 0 and pos.y < trixel_bounds.y \
	and pos.z >= 0 and pos.z < trixel_bounds.z

func get_trixel(pos : Vector3i) -> bool:
	return data.has(pos)
	
func get_adjacent_trixel(pos : Vector3i, face : Face) -> bool:
	return data.has(pos + TrixelContainer.get_face_normal(face))

func is_trixel_face_solid(pos : Vector3i, face : Face) -> bool:
	return data.has(pos) and not data.has(pos + TrixelContainer.get_face_normal(face))

func set_trixel(pos : Vector3i, state : bool):
	if state:
		if pos.x >= 0 and pos.x < trixel_bounds.x \
		and pos.y >= 0 and pos.y < trixel_bounds.y \
		and pos.z >= 0 and pos.z < trixel_bounds.z :
			data[pos] = true
	if not state: data.erase(pos)
	
func set_trixels(positions : Array, state : bool):
	if state:
		for pos in positions:
			if pos.x >= 0 and pos.x < trixel_bounds.x \
			and pos.y >= 0 and pos.y < trixel_bounds.y \
			and pos.z >= 0 and pos.z < trixel_bounds.z :
				data[pos] = true
	if not state:
		for pos in positions:
			data.erase(pos)
				
func initialize_trile(
	size : Vector3i = DEFAULT_TRILE_SIZE, 
	resolution : int = DEFAULT_TRIXELS_PER_TRILE
):
	trile_size = size
	trixels_per_trile = resolution
	_recalculate_constants()
	initialize_data_buffer()


enum Face {FRONT, BACK, TOP, BOTTOM, LEFT, RIGHT}

static func get_face_normal(face : Face) -> Vector3i:
	const normal_lookup = [
		Vector3i.FORWARD, # Face.FRONT
		Vector3i.BACK,    # Face.BACK
		Vector3i.UP,      # Face.TOP
		Vector3i.DOWN,    # Face.BOTTOM
		Vector3i.LEFT,    # Face.LEFT
		Vector3i.RIGHT    # Face.RIGHT
	]
	return normal_lookup[face]

static func get_face_tangent(face : Face) -> Vector3i:
	const tangent_lookup = [
		Vector3i.RIGHT,   # Face.FRONT
		Vector3i.LEFT,    # Face.BACK
		Vector3i.RIGHT,   # Face.TOP
		Vector3i.RIGHT,   # Face.BOTTOM
		Vector3i.BACK,    # Face.LEFT
		Vector3i.FORWARD  # Face.RIGHT
	]
	return tangent_lookup[face]
	
static func get_face_cotangent(face : Face) -> Vector3i:
	const cotangent_lookup = [
		Vector3i.DOWN,    # Face.FRONT
		Vector3i.DOWN,    # Face.BACK
		Vector3i.BACK,    # Face.TOP
		Vector3i.FORWARD, # Face.BOTTOM
		Vector3i.DOWN,    # Face.LEFT
		Vector3i.DOWN     # Face.RIGHT
	]
	return cotangent_lookup[face]
