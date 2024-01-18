class_name TrixelEditor extends Node3D

var trixels : TrixelContainer
var trixel_materializer : TrixelMaterializer
var boundaries_object : Node3D

var temporary_csg_fillers : Array = []

func _ready():
	trixel_materializer = $trixel_materializer as TrixelMaterializer
	trixel_materializer.materialized.connect(_trixel_materialized)
	boundaries_object = $boundaries
	
	var start = Time.get_ticks_usec()
	
	trixels = TrixelContainer.new()
	trixels.initialize_trile()
	fill(Vector3i.ZERO, trixels.trixel_bounds - Vector3i.ONE, true)
	
	var end = Time.get_ticks_usec()
	var worker_time = (end-start)/1000.0
	print("TrixelEditor._ready() - %f ms" % worker_time)
	
	_rebuild_mesh()

func _rebuild_mesh():
	boundaries_object.scale = trixels.trile_size as Vector3 + Vector3.ONE * 0.01
	trixel_materializer.materialize(trixels)


func _process(_delta):
	var mode: int = 0
	if Input.is_action_just_pressed("debug_refresh"): mode = 1
	if Input.is_action_just_pressed("debug_fill_random"): mode = 2
	if Input.is_action_just_pressed("debug_clear_random"): mode = 3
	
	if mode > 0:
		var rng = RandomNumberGenerator.new()
		var corner1 = Vector3i(
			rng.randi_range(0, trixels.trixel_bounds.x - 1),
			rng.randi_range(0, trixels.trixel_bounds.y - 1),
			rng.randi_range(0, trixels.trixel_bounds.z - 1),
		)
		var corner2 = Vector3i(
			rng.randi_range(0, trixels.trixel_bounds.x - 1),
			rng.randi_range(0, trixels.trixel_bounds.y - 1),
			rng.randi_range(0, trixels.trixel_bounds.z - 1),
		)
		
		if mode > 1: fill(corner1, corner2, true if mode == 3 else false)
		if mode == 1: _rebuild_mesh()

func _trixel_materialized(_trixels : TrixelContainer, interrupted : bool):
	if not interrupted: 
		_clear_csg_fillers()

func _create_csg_filler(mins : Vector3, maxs : Vector3, state : bool):
	var box = CSGBox3D.new()
	
	var trixels_per_trile = trixels.trixels_per_trile
	var trile_size = trixels.trile_size as Vector3
	
	box.scale = (maxs - mins + Vector3.ONE) / trixels_per_trile
	box.position = ((mins + maxs + Vector3.ONE) / trixels_per_trile - trile_size) * 0.5
	
	box.operation = CSGShape3D.OPERATION_UNION if state else CSGShape3D.OPERATION_SUBTRACTION
	box.material = trixel_materializer.material
	trixel_materializer.add_child(box)
	temporary_csg_fillers.append(box)

func _clear_csg_fillers():
	for filler in temporary_csg_fillers:
		filler.queue_free()
	temporary_csg_fillers.clear()

func fill(corner1 : Vector3i, corner2 : Vector3i, state: bool):
	var smallest = Vector3i(
		min(corner1.x, corner2.x),
		min(corner1.y, corner2.y),
		min(corner1.z, corner2.z),
	)
	var largest = Vector3i(
		max(corner1.x, corner2.x),
		max(corner1.y, corner2.y),
		max(corner1.z, corner2.z),
	)
	
	trixels.fill_trixels(smallest, largest, state)
	_create_csg_filler(smallest, largest, state)
