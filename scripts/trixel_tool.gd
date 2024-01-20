class_name TrixelTool extends Node

enum Mode {NONE, PRIMARY, SECONDARY}

@export var trile_editor : TrileEditor
@export var debug_label : Label
@export var primary_action_button : Button
@export var secondary_action_button : Button
@export var cursor_oversize : float

@onready var cursor := $cursor

var mode : Mode

var _current_mouse_position : Vector2

var _selecting : bool
var _selection_start_trixel_pos : Vector3i
var _last_trixel_position : Vector3i
var _aiming_at_trile : bool

func _ready():
	primary_action_button.toggled.connect(_on_buttons_toggled)
	secondary_action_button.toggled.connect(_on_buttons_toggled)
	
	debug_label.text = ""

func _on_buttons_toggled(_b):
	if primary_action_button.button_pressed: mode = Mode.PRIMARY
	elif secondary_action_button.button_pressed: mode = Mode.SECONDARY
	else: mode = Mode.NONE

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
	var switch := false
	if Input.is_action_just_pressed("tool_alt"):
		switch = true
	if Input.is_action_just_released("tool_alt"):
		switch = true
	
	if switch:
		if mode == Mode.PRIMARY: 
			secondary_action_button.button_pressed = true
		elif mode == Mode.SECONDARY: 
			primary_action_button.button_pressed = true
	

func _process(_delta):
	if mode == Mode.NONE: return
	
	_reload_aimed_trile_pos()
	_update_cursor()
	_update_debug_label()
	

func _update_cursor():
	cursor.visible = _selecting or _aiming_at_trile
	
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


func _cast_mouse_in_trile() -> TrixelRaycaster.Result:
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
	trile_editor.fill(start, end, mode == Mode.PRIMARY)
	trile_editor._rebuild_mesh()
	_selecting = false


# functions to overload
func get_debug_text() -> String: return ""
func on_start_selection(): pass
func on_end_selection(): pass
func is_raycast_hit_valid(_hit : TrixelRaycaster.Result) -> bool: return false
func should_offset_raycast_hit(_hit : TrixelRaycaster.Result) -> bool: return false
