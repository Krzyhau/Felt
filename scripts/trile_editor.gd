class_name TrileEditor extends Node3D

var trile : Trile
var visual_boundaries : Node3D
var mesh_node : CSGMesh3D

var temporary_csg_fillers : Array = []

func _ready():
	visual_boundaries = $boundaries
	mesh_node = $mesh
	initialize_new_trile()
	trile.rebuild_mesh()

func _process(_delta):
	if Input.is_action_just_pressed("debug_refresh"): trile.rebuild_mesh()

func _trile_materialized(_trile : Trile, _mesh_data : Array, interrupted : bool):
	if not interrupted: 
		_clear_csg_fillers()

func _create_csg_filler(mins : Vector3, maxs : Vector3, state : bool):
	var box := CSGBox3D.new()
	
	var region_size := (maxs - mins + Vector3.ONE)
	var region_midpoint := (mins + maxs + Vector3.ONE) * 0.5
	
	box.scale = region_size / trile.resolution
	box.position = region_midpoint / trile.resolution - Vector3.ONE * (trile.size / 2.0)
	box.operation = CSGShape3D.OPERATION_UNION if state else CSGShape3D.OPERATION_SUBTRACTION

	box.material = _create_material_for_csg_filler(box)
	
	mesh_node.add_child(box)
	temporary_csg_fillers.append(box)

func _create_material_for_csg_filler(box : CSGBox3D) -> ShaderMaterial:
	var inner_faces := box.operation == CSGShape3D.OPERATION_SUBTRACTION
	var size := box.scale / trile.size
	var offset := (box.position / trile.size) + Vector3.ONE * 0.5
	
	var material := ShaderMaterial.new()
	material.shader = trile.material.shader
	material.set_shader_parameter("TEXTURE", trile.cubemap)
	material.set_shader_parameter("calculate_projection", true)
	material.set_shader_parameter("inner_faces", inner_faces)
	material.set_shader_parameter("size", size)
	material.set_shader_parameter("offset", offset)
	return material

func _clear_csg_fillers():
	for filler in temporary_csg_fillers:
		filler.queue_free()
	temporary_csg_fillers.clear()

func initialize_new_trile():
	initialize_trile(Trile.new())
	fill(Vector3i.ZERO, Vector3i.ONE * (trile.size_in_trixels - 1), true)

func initialize_trile(new_trile : Trile):
	self.trile = new_trile
	mesh_node.mesh = new_trile
	new_trile.materializer.materialized.connect(_trile_materialized)
	visual_boundaries.scale = Vector3.ONE * (trile.size + 0.01)

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

func paint(pos : Vector3i, face : Trile.Face, color : Color):
	trile.cubemap.paint(pos, face, color)

func get_global_to_trixel(global_pos : Vector3) -> Vector3:
	return trile.local_to_trixel(self.to_local(global_pos))

func get_trixel_to_global(trixel_pos : Vector3) -> Vector3:
	return self.to_global(trile.trixel_to_local(trixel_pos))
	
