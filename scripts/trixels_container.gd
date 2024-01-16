class_name TrixelContainer extends Resource

const DEFAULT_TRIXELS_PER_TRILE = 16
const DEFAULT_TRILE_SIZE = Vector3i.ONE

var _trixels_per_trile : int
var _trile_size : Vector3i

var _trixels : Array

func get_trixels_per_trile() -> int:
	return _trixels_per_trile
	
func get_trile_size() -> Vector3i:
	return _trile_size

func get_trixel_bounds() -> Vector3i:
	return _trile_size * _trixels_per_trile
	
func get_trixels_count() -> int:
	var bounds = get_trixel_bounds()
	return bounds.x * bounds.y * bounds.z
	
func get_trixel_index(pos : Vector3i) -> int:
	var bounds = get_trixel_bounds()
	return pos.x + pos.y * bounds.x + pos.z * bounds.x * bounds.y

func is_within_bounds(pos : Vector3i) -> bool:
	var bounds = get_trixel_bounds()
	return pos.x >= 0 and pos.x < bounds.x \
	and pos.y >= 0 and pos.y < bounds.y \
	and pos.z >= 0 and pos.z < bounds.z
	

func get_trixel(pos : Vector3i) -> bool:
	if is_within_bounds(pos):
		return _trixels[get_trixel_index(pos)]
	else: return false
	
func get_adjacent_trixel(pos : Vector3i, face : Face) -> bool:
	return get_trixel(pos + get_face_normal(face))

func set_trixel(pos : Vector3i, state : bool):
	if is_within_bounds(pos): _trixels[get_trixel_index(pos)] = state

func initialize_trile(
	size : Vector3i = DEFAULT_TRILE_SIZE, 
	resolution : int = DEFAULT_TRIXELS_PER_TRILE
):
	_trile_size = size
	_trixels_per_trile = resolution
	_trixels = []
	_trixels.resize(get_trixels_count())
	_trixels.fill(false)


enum Face {FRONT, BACK, TOP, BOTTOM, LEFT, RIGHT}

static func get_face_normal(face : Face) -> Vector3i:
	match face:
		Face.FRONT: return Vector3i.FORWARD
		Face.BACK: return Vector3i.BACK
		Face.TOP: return Vector3i.UP
		Face.BOTTOM: return Vector3i.DOWN
		Face.LEFT: return Vector3i.LEFT
		Face.RIGHT: return Vector3i.RIGHT
	return Vector3i.ZERO

static func get_face_tangent(face : Face) -> Vector3i:
	match face:
		Face.FRONT: return Vector3i.RIGHT
		Face.BACK: return Vector3i.LEFT
		Face.TOP: return Vector3i.RIGHT
		Face.BOTTOM: return Vector3i.RIGHT
		Face.LEFT: return Vector3i.BACK
		Face.RIGHT: return Vector3i.FORWARD
	return Vector3i.ZERO
	
static func get_face_cotangent(face : Face) -> Vector3i:
	match face:
		Face.FRONT: return Vector3i.DOWN
		Face.BACK: return Vector3i.DOWN
		Face.TOP: return Vector3i.BACK
		Face.BOTTOM: return Vector3i.FORWARD
		Face.LEFT: return Vector3i.DOWN
		Face.RIGHT: return Vector3i.DOWN
	return Vector3i.ZERO
