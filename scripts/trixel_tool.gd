class_name TrixelTool extends Node

enum Mode {PLACING, ERASING}

@export var trixel_editor : TrixelEditor
@export var debug_label : Label
@export var mode : Mode
@export var cursor_oversize : float

@onready var cursor := $cursor

var _current_mouse_position : Vector2

var _selecting : bool
var _selection_start_trixel_pos : Vector3i
var _last_trixel_position : Vector3i
var _aiming_at_trile : bool
var _switch_mode : bool


func _input(event):
	if event is InputEventMouseMotion:
		_current_mouse_position = event.position
	if event is InputEventMouseButton and event.button_index == 1:
		if event.pressed: _start_selection()
		else: _execute_selection()
		
	if Input.is_action_just_pressed("tool_alt"):
		_switch_mode = true
	if Input.is_action_just_released("tool_alt"):
		_switch_mode = false

func _process(_delta):
	_reload_aimed_trile_pos()
	_update_cursor()

	var pos_text := "none"
	if _aiming_at_trile or _selecting:
		pos_text = ("%s" % _last_trixel_position)
		pos_text = pos_text.substr(1, pos_text.length() - 2)
	debug_label.text = "Trixel pos: %s" % pos_text

func _update_cursor():
	cursor.visible = _selecting or _aiming_at_trile
	var material : StandardMaterial3D = cursor.get_surface_override_material(0)
	const color_placing := Color(0.0,0.0,1.0,0.5)
	const color_erasing := Color(1.0,0.0,0.0,0.5)
	material.albedo_color = color_placing if get_current_mode() == Mode.PLACING else color_erasing
	material.emission = material.albedo_color
	
	var start_pos := trixel_editor.get_trixel_to_global(_last_trixel_position)
	var end_pos := trixel_editor.get_trixel_to_global(_selection_start_trixel_pos)
	if not _selecting: end_pos = start_pos
	
	self.global_position = Vector3(
		minf(start_pos.x, end_pos.x) - cursor_oversize,
		minf(start_pos.y, end_pos.y) - cursor_oversize,
		minf(start_pos.z, end_pos.z) - cursor_oversize,
	)
	var min_size := Vector3.ONE / trixel_editor.trixels.trixels_per_trile
	var oversize_scale := Vector3.ONE * cursor_oversize * 2.0
	self.scale = min_size + oversize_scale + (end_pos - start_pos).abs()

func _reload_aimed_trile_pos():
	var cast_result = _cast_mouse_in_trile()
	_aiming_at_trile = (cast_result != null)
	if not _aiming_at_trile: return
	
	var position : Vector3i = cast_result.position
	var normal := TrixelContainer.get_face_normal(cast_result.face)
	
	var should_offset : bool = get_current_mode() == Mode.PLACING or not cast_result.hit_trixel
	var offset_within_bounds := trixel_editor.trixels.is_within_bounds(position + normal)
	var within_bounds := trixel_editor.trixels.is_within_bounds(position)
	
	if (should_offset and offset_within_bounds) or not within_bounds: 
		position += normal
	
	_last_trixel_position = position

func _cast_mouse_in_trile() -> Variant:
	var camera := get_viewport().get_camera_3d()
	var start_pos := camera.project_position(_current_mouse_position, 0.0)
	var moved_pos := camera.project_position(_current_mouse_position, 1.0)
	
	start_pos = trixel_editor.get_global_to_trixel(start_pos)
	moved_pos = trixel_editor.get_global_to_trixel(moved_pos)
	
	var dir := (moved_pos - start_pos).normalized()
	
	return TrixelRaycaster.cast(trixel_editor.trixels, start_pos, dir)

func _start_selection():
	_selecting = true
	_selection_start_trixel_pos = _last_trixel_position

func _execute_selection():
	var start := _selection_start_trixel_pos
	var end := _last_trixel_position
	trixel_editor.fill(start, end, get_current_mode() == Mode.PLACING)
	trixel_editor._rebuild_mesh()
	_selecting = false
	
func get_current_mode() -> Mode:
	return ((mode + (1 if _switch_mode else 0)) % 2) as Mode
