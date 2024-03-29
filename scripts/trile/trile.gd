class_name Trile extends ArrayMesh

enum Face {FRONT, BACK, TOP, BOTTOM, LEFT, RIGHT}

const DEFAULT_RESOLUTION = 16
const DEFAULT_SIZE = Vector3i.ONE

var resolution : int # how many trixels within a trile unit
var size : Vector3 # the size of a trile, in units
var trixel_bounds : Vector3i # the size of a trile, in trixels
var trixels_count : int # the number of triles stored in this trile

var y_index : int
var z_index : int

var buffer : PackedByteArray
var materializer : TrileMaterializer
var dematerializer : TrileDematerializer
var cubemap : TrileCubemap
var material : ShaderMaterial

var should_dematerialize : bool

func _init(
	trile_size : Vector3 = DEFAULT_SIZE, 
	trile_resolution : int = DEFAULT_RESOLUTION
):
	resolution = trile_resolution
	size = (trile_size * trile_resolution).round() / trile_resolution
	_recalculate_constants()
	_initialize_data_buffer()
	_initialize_cubemap_and_material()
	_create_materializer()
	_create_dematerializer()

func _initialize_data_buffer():
	buffer = PackedByteArray()
	buffer.resize(trixels_count)

func _recalculate_constants():
	trixel_bounds = size * resolution
	trixels_count = trixel_bounds.x * trixel_bounds.y * trixel_bounds.z
	y_index = trixel_bounds.x
	z_index = trixel_bounds.x * trixel_bounds.y


func _initialize_cubemap_and_material():
	cubemap = TrileCubemap.new(self)
	material = ShaderMaterial.new()
	material.shader = preload("res://graphics/shaders/trixel_texture_projection.gdshader")
	material.set_shader_parameter("TEXTURE", cubemap)

func _create_materializer():
	materializer = TrileMaterializer.new(self)
	materializer.materialized.connect(_on_materialized)

func _create_dematerializer():
	dematerializer = TrileDematerializer.new(self)
	dematerializer.dematerialized.connect(_on_dematerialized)

func _on_materialized(_trile : Trile, mesh_data : Array, _interrupted : bool):
	if _interrupted: return
	
	clear_surfaces()
	var has_vertices := len(mesh_data[Mesh.ARRAY_VERTEX]) != 0
	if has_vertices:
		add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_data)
		surface_set_material(0, material)

func _on_dematerialized(_trile : Trile, trixel_data : PackedByteArray, _interrupted : bool):
	if _interrupted: return
	should_dematerialize = false
	buffer = trixel_data
	rebuild_mesh()

func rebuild_mesh():
	if should_dematerialize:
		dematerializer.dematerialize()
	else:
		materializer.materialize()
	
func set_raw_mesh(mesh_data : Array):
	clear_surfaces()
	add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_data)
	surface_set_material(0, material)
	should_dematerialize = true

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

func trixel_to_local(trixel_pos : Vector3) -> Vector3:
	return (trixel_pos / resolution) - size / 2.0

func local_to_trixel(local_pos : Vector3) -> Vector3:
	return (local_pos + size / 2.0) * resolution

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
	
static func get_face_name(face : Face) -> String:
	const name_lookup := [
		"Front", "Back", "Top", "bottom", "Left", "Right"
	]
	return name_lookup[face]

static func get_face_rotation_degrees(face : Face) -> Vector3:
	const rotation_lookup := [
		Vector3(0,0,0),   # Face.FRONT
		Vector3(0,180,0),   # Face.BACK
		Vector3(-90,0,0),   # Face.TOP
		Vector3(90,0,0),   # Face.BOTTOM
		Vector3(0,270,0),   # Face.LEFT
		Vector3(0,90,0),   # Face.RIGHT
	]
	return rotation_lookup[face]
