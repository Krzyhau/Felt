class_name TrixelTool extends Node

enum Mode {NONE, PRIMARY, ALT_PRIMARY, SECONDARY}

@export var trile_editor : TrileEditor
@export var debug_label : Label
@export var primary_action_button : Button
@export var alt_primary_action_button : Button
@export var secondary_action_button : Button
@export var cursor_oversize : float

@onready var cursor := $cursor

var mode : Mode

var _current_mouse_position : Vector2

var _selecting : bool
var _use_selection_resizing : bool
var _last_trixel_position : Vector3i
var _last_trixel_face : int
var _selection_start_trixel_pos : Vector3i
var _aiming_at_trile : bool
var _use_alt_tool : bool

func _ready():
	_register_button(primary_action_button, Mode.PRIMARY)
	_register_button(alt_primary_action_button, Mode.ALT_PRIMARY)
	_register_button(secondary_action_button, Mode.SECONDARY)
	
	debug_label.text = ""
	_use_selection_resizing = true

func _register_button(button : Button, assigned_mode : Mode):
	if button == null: return
	button.toggled.connect(func(toggled_on):
		_on_button_toggled(assigned_mode, toggled_on)
	)

func _on_button_toggled(assigned_mode : Mode, toggled_on : bool):
	if toggled_on:
		mode = assigned_mode
		_use_alt_tool = true if assigned_mode == Mode.ALT_PRIMARY else false
	elif mode == assigned_mode:
		mode = Mode.NONE

func _input(event):
	if mode == Mode.NONE: return
	
	_input_mouse_actions(event)
	_input_handle_mode_switching()

func _input_mouse_actions(event):
	if event is InputEventMouseMotion:
		_current_mouse_position = event.position
	if event is InputEventMouseButton and event.button_index == 1:
		if event.pressed and UIMouseZone.is_mouse_over: _start_selection()
		else: _execute_selection()

func _input_handle_mode_switching():
	if secondary_action_button == null: return
	
	var switch_on := false
	var switch_off := false
	if Input.is_action_just_pressed("tool_alt"):
		switch_on = true
	if Input.is_action_just_released("tool_alt"):
		switch_off = true
	
	if switch_on or switch_off:
		if mode == Mode.PRIMARY || mode == Mode.ALT_PRIMARY:
			secondary_action_button.button_pressed = true
		elif mode == Mode.SECONDARY: 
			if _use_alt_tool: alt_primary_action_button.button_pressed = true
			else: primary_action_button.button_pressed = true
	

func _process(_delta):
	if mode == Mode.NONE: 
		cursor.visible = false
		return
	
	_reload_aimed_trile_pos()
	_update_cursor()
	_update_debug_label()
	

func _update_cursor():
	cursor.visible = _selecting or _aiming_at_trile
	
	var start_pos := trile_editor.get_trixel_to_global(_last_trixel_position)
	var end_pos := trile_editor.get_trixel_to_global(_selection_start_trixel_pos)
	if not _selecting or not _use_selection_resizing: end_pos = start_pos
	
	self.global_position = Vector3(
		minf(start_pos.x, end_pos.x) - cursor_oversize,
		minf(start_pos.y, end_pos.y) - cursor_oversize,
		minf(start_pos.z, end_pos.z) - cursor_oversize,
	)
	var min_size := Vector3.ONE / trile_editor.trile.get_resolution()
	var oversize_scale := Vector3.ONE * cursor_oversize * 2.0
	self.scale = min_size + oversize_scale + (end_pos - start_pos).abs()
	
	cursor.rotation_degrees = Trile.get_face_rotation_degrees(_last_trixel_face)

func _update_debug_label():
	debug_label.text = get_debug_text()

func _reload_aimed_trile_pos():
	var cast_result := _cast_mouse_in_trile()
	_aiming_at_trile = is_raycast_hit_valid(cast_result)
	
	if not _aiming_at_trile: return
	
	var position : Vector3i = cast_result.position
	var normal := Trile.get_face_normal(cast_result.face)
	
	if should_offset_raycast_hit(cast_result): 
		position += normal
	
	_last_trixel_position = position
	_last_trixel_face = cast_result.face


func _cast_mouse_in_trile() -> TrixelRaycaster.Result:
	var camera := get_viewport().get_camera_3d()
	var start_pos := camera.project_position(_current_mouse_position, 0.0)
	var moved_pos := camera.project_position(_current_mouse_position, 1.0)
	
	start_pos = trile_editor.get_global_to_trixel(start_pos)
	moved_pos = trile_editor.get_global_to_trixel(moved_pos)
	
	var dir := (moved_pos - start_pos).normalized()
	
	return TrixelRaycaster.cast_in_trile_space(trile_editor.trile, start_pos, dir)

func _start_selection():
	if not _aiming_at_trile or _selecting: return
	_selecting = true
	_selection_start_trixel_pos = _last_trixel_position
	on_selection_started()

func _execute_selection():
	if not _selecting: return
	on_selection_finalized()
	_selecting = false


# functions to overload
func get_debug_text() -> String: return ""
func is_raycast_hit_valid(_hit : TrixelRaycaster.Result) -> bool: return false
func should_offset_raycast_hit(_hit : TrixelRaycaster.Result) -> bool: return false
func on_selection_started(): pass
func on_selection_finalized(): pass
