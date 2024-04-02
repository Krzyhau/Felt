class_name TrileEditor extends Node3D

var trile : Trile
var visual_boundaries : Node3D
var mesh_node : CSGMesh3D

var temporary_csg_fillers : Array = []

func _ready():
	visual_boundaries = $boundaries
	mesh_node = $mesh
	initialize_new_trile()

func _process(_delta):
	if Input.is_action_just_pressed("debug_refresh"): trile.rebuild_mesh()

func initialize_new_trile():
	var new_trile = Trile.create(Vector3.ONE, 16);
	new_trile.fill_trixels(Vector3i.ZERO, new_trile.get_trixel_bounds() - Vector3i.ONE, true)
	initialize_trile(new_trile)

func initialize_trile(new_trile : Trile):
	self.trile = new_trile
	new_trile.set_material(mesh_node.material)
	mesh_node.mesh = new_trile
	visual_boundaries.scale = (trile.get_size() as Vector3) + Vector3.ONE * 0.01
	trile.rebuild_mesh()

func fill(corner1 : Vector3i, corner2 : Vector3i, state: bool):
	trile.fill_trixels(corner1, corner2, state)

func paint(pos : Vector3i, face : int, color : Color, fill_mode : bool):
	if fill_mode: trile.get_cubemap().flood_fill(pos, face, color)
	else: trile.get_cubemap().paint(pos, face, color)

func pick_color(pos : Vector3i, face : int) -> Color:
	return trile.get_cubemap().pick_color(pos, face)

func get_global_to_trixel(global_pos : Vector3) -> Vector3:
	return trile.local_to_trixel(self.to_local(global_pos))

func get_trixel_to_global(trixel_pos : Vector3) -> Vector3:
	return self.to_global(trile.trixel_to_local(trixel_pos))
	
