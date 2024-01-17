class_name TrixelEditor extends Node3D

var trixels : TrixelContainer
var trixel_materializer : TrixelMaterializer
var boundaries_object : Node3D

func _ready():
	trixel_materializer = $trixel_materializer as TrixelMaterializer
	boundaries_object = $boundaries
	
	var start = Time.get_ticks_usec()
	
	trixels = TrixelContainer.new()
	trixels.initialize_trile(Vector3i(4,4,4))
	
	fill(Vector3i.ZERO, trixels.trixel_bounds - Vector3i.ONE, true, false)
	
	var end = Time.get_ticks_usec()
	var worker_time = (end-start)/1000.0
	print("TrixelEditor._ready() - %f ms" % worker_time)
	
	_rebuild_mesh()

func _rebuild_mesh():
	boundaries_object.scale = trixels.trile_size as Vector3 + Vector3.ONE * 0.01
	trixel_materializer.materialize(trixels)


func _process(delta):
	if Input.is_action_just_pressed("debug_wireframe"):
		_rebuild_mesh()


func fill(corner1 : Vector3i, corner2 : Vector3i, state: bool, rebuild : bool = true):
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
	
	var trixels_to_fill = []
	
	for x in range(smallest.x, largest.x+1):
		for y in range(smallest.y, largest.y+1):
			for z in range(smallest.z, largest.z+1):
				trixels_to_fill.append(Vector3i(x,y,z))
	
	trixels.set_trixels(trixels_to_fill, state)
	
	if rebuild: _rebuild_mesh()
