class_name TrixelTool extends Node

enum Mode {NONE, PLACING, ERASING}

@export var trile_editor : TrileEditor
@export var debug_label : Label
@export var place_button : Button
@export var erase_button : Button
@export var cursor_oversize : float

@onready var cursor := $cursor

var mode : Mode

var _current_mouse_position : Vector2

var _selecting : bool
var _selection_start_trixel_pos : Vector3i
var _last_trixel_position : Vector3i
var _aiming_at_trile : bool

func _ready():
	place_button.toggled.connect(_on_buttons_toggled)
	erase_button.toggled.connect(_on_buttons_toggled)
	
	debug_label.text = ""

func _on_buttons_toggled(_b):
	if place_button.button_pressed: mode = Mode.PLACING
	elif erase_button.button_pressed: mode = Mode.ERASING
	else: mode = Mode.NONE

func _input(event):
	if mode == Mode.NONE: return
	
	_input_mouse_actions(event)
	_input_handle_mode_switching()

func _input_mouse_actions(event):
	if event is InputEventMouseMotion:
		_current_mouse_position = event.position
	if event is InputEventMouseButton and event.button_index == 1:
		if event.pressed: _start_selection()
		else: _execute_selection()

func _input_handle_mode_switching():
	var switch := false
	if Input.is_action_just_pressed("tool_alt"):
		switch = true
	if Input.is_action_just_released("tool_alt"):
		switch = true
	
	if switch:
		if mode == Mode.PLACING: 
			erase_button.pressed.emit()
			erase_button.button_pressed = true
		elif mode == Mode.ERASING: 
			place_button.pressed.emit()
			place_button.button_pressed = true
	

func _process(_delta):
	if mode == Mode.NONE: return
	
	_reload_aimed_trile_pos()
	_update_cursor()
	_update_debug_label()
	

func _update_cursor():
	cursor.visible = _selecting or _aiming_at_trile
	var material : StandardMaterial3D = cursor.get_surface_override_material(0)
	const color_placing := Color(0.0,0.0,1.0,0.5)
	const color_erasing := Color(1.0,0.0,0.0,0.5)
	material.albedo_color = color_placing if mode == Mode.PLACING else color_erasing
	material.emission = material.albedo_color
	
	var start_pos := trile_editor.get_trixel_to_global(_last_trixel_position)
	var end_pos := trile_editor.get_trixel_to_global(_selection_start_trixel_pos)
	if not _selecting: end_pos = start_pos
	
	self.global_position = Vector3(
		minf(start_pos.x, end_pos.x) - cursor_oversize,
		minf(start_pos.y, end_pos.y) - cursor_oversize,
		minf(start_pos.z, end_pos.z) - cursor_oversize,
	)
	var min_size := Vector3.ONE / trile_editor.trile.resolution
	var oversize_scale := Vector3.ONE * cursor_oversize * 2.0
	self.scale = min_size + oversize_scale + (end_pos - start_pos).abs()

func _update_debug_label():
	var pos_text := "none"
	if _aiming_at_trile or _selecting:
		pos_text = ("%s" % _last_trixel_position)
		pos_text = pos_text.substr(1, pos_text.length() - 2).replace(",", " ")
	debug_label.text = "Hovering: %s" % pos_text

func _update_buttons_focus_states():
	pass

func _reload_aimed_trile_pos():
	var cast_result = _cast_mouse_in_trile()
	_aiming_at_trile = (cast_result != null)
	if not _aiming_at_trile: return
	
	var position : Vector3i = cast_result.position
	var normal := Trile.get_face_normal(cast_result.face)
	
	var should_offset : bool = mode == Mode.PLACING
	var offset_within_bounds := trile_editor.trile.contains_trixel_pos(position + normal)
	var within_bounds := trile_editor.trile.contains_trixel_pos(position)
	
	if (should_offset and offset_within_bounds) or not within_bounds: 
		position += normal
	
	_last_trixel_position = position

func _cast_mouse_in_trile() -> Variant:
	var camera := get_viewport().get_camera_3d()
	var start_pos := camera.project_position(_current_mouse_position, 0.0)
	var moved_pos := camera.project_position(_current_mouse_position, 1.0)
	
	start_pos = trile_editor.get_global_to_trixel(start_pos)
	moved_pos = trile_editor.get_global_to_trixel(moved_pos)
	
	var dir := (moved_pos - start_pos).normalized()
	
	return TrixelRaycaster.cast_in_trile_space(trile_editor.trile, start_pos, dir)

func _start_selection():
	if not _aiming_at_trile: return
	_selecting = true
	_selection_start_trixel_pos = _last_trixel_position

func _execute_selection():
	if not _selecting: return
	var start := _selection_start_trixel_pos
	var end := _last_trixel_position
	trile_editor.fill(start, end, mode == Mode.PLACING)
	trile_editor._rebuild_mesh()
	_selecting = false
