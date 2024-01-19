class_name TrixelTool extends Node

@export var trixel_editor : TrixelEditor
@export var debug_label : Label

@onready var cursor := $cursor

var _current_mouse_position : Vector2

func _input(event):
	if event is InputEventMouseMotion:
		_current_mouse_position = event.position

func _process(_delta):
	self.scale = Vector3.ONE / trixel_editor.trixels.trixels_per_trile
	var aimed_pos = get_aimed_trile_pos()
	
	cursor.visible = aimed_pos != null
	
	if aimed_pos != null:
		debug_label.text = "Trixel pos: %s" % aimed_pos
		var real_pos := trixel_editor.get_trixel_to_global(aimed_pos)
		self.global_position = real_pos
	else:
		debug_label.text = "Trixel pos: none"

func get_aimed_trile_pos() -> Variant:
	var cast_result = _cast_mouse_in_trile()
	if cast_result == null: return null
	
	var position = cast_result.position
	var normal = TrixelContainer.get_face_normal(cast_result.face)
	
	if trixel_editor.trixels.is_within_bounds(position + normal):
		position += normal
	
	return position

func _cast_mouse_in_trile() -> Variant:
	var camera := get_viewport().get_camera_3d()
	var start_pos := camera.project_position(_current_mouse_position, 0.0)
	var moved_pos := camera.project_position(_current_mouse_position, 1.0)
	
	start_pos = trixel_editor.get_global_to_trixel(start_pos)
	moved_pos = trixel_editor.get_global_to_trixel(moved_pos)
	
	var dir := (moved_pos - start_pos).normalized()
	
	return TrixelRaycaster.cast(trixel_editor.trixels, start_pos, dir)
