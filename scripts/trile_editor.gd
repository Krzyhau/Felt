class_name TrileEditor extends Node3D

var trile : Trile
var materializer : TrileMaterializer
var visual_boundaries : Node3D

var temporary_csg_fillers : Array = []

func _ready():
	materializer = $materializer as TrileMaterializer
	materializer.materialized.connect(_trile_materialized)
	visual_boundaries = $boundaries
	
	var start := Time.get_ticks_usec()
	
	trile = Trile.new()
	trile.initialize_trile()
	fill(Vector3i.ZERO, trile.trixel_bounds - Vector3i.ONE, true)
	
	var end = Time.get_ticks_usec()
	var worker_time = (end-start)/1000.0
	print("TrileEditor._ready() - %f ms" % worker_time)
	
	_rebuild_mesh()

func _rebuild_mesh():
	visual_boundaries.scale = (trile.size as Vector3) + Vector3.ONE * 0.01
	materializer.materialize(trile)


func _process(_delta):
	if Input.is_action_just_pressed("debug_refresh"): _rebuild_mesh()

func _trile_materialized(_trile : Trile, interrupted : bool):
	if not interrupted: 
		_clear_csg_fillers()

func _create_csg_filler(mins : Vector3, maxs : Vector3, state : bool):
	var box := CSGBox3D.new()
	
	var resolution := trile.resolution
	var trile_size := trile.size as Vector3
	var trixel_bounds := trile.trixel_bounds as Vector3
	
	var region_size := (maxs - mins + Vector3.ONE)
	var region_midpoint := (mins + maxs + Vector3.ONE) * 0.5
	
	box.scale = region_size / resolution
	box.position = region_midpoint / resolution - trile_size * 0.5
	
	box.operation = CSGShape3D.OPERATION_UNION if state else CSGShape3D.OPERATION_SUBTRACTION
	
	var material := materializer.material.duplicate(true) as ShaderMaterial
	material.set_shader_parameter("calculate_projection", true)
	material.set_shader_parameter("inner_faces", not state)
	material.set_shader_parameter("size", region_size / trixel_bounds)
	material.set_shader_parameter("offset", region_midpoint / trixel_bounds)
	box.material = material
	
	materializer.add_child(box)
	temporary_csg_fillers.append(box)

func _clear_csg_fillers():
	for filler in temporary_csg_fillers:
		filler.queue_free()
	temporary_csg_fillers.clear()

func fill(corner1 : Vector3i, corner2 : Vector3i, state: bool):
	var smallest := Vector3i(
		min(corner1.x, corner2.x),
		min(corner1.y, corner2.y),
		min(corner1.z, corner2.z),
	)
	var largest := Vector3i(
		max(corner1.x, corner2.x),
		max(corner1.y, corner2.y),
		max(corner1.z, corner2.z),
	)
	
	trile.fill_trixels(smallest, largest, state)
	_create_csg_filler(smallest, largest, state)


func get_global_to_trixel(global_pos : Vector3) -> Vector3:
	return trile.local_to_trixel(self.to_local(global_pos))

func get_trixel_to_global(trixel_pos : Vector3) -> Vector3:
	return self.to_global(trile.trixel_to_local(trixel_pos))
	
