class_name TrixelPainter extends TrixelTool

@export var primary_color_button : ColorButton
@export var secondary_color_button : ColorButton

var _painter_cursor_mesh : MeshInstance3D
var _picker_cursor_mesh : MeshInstance3D

func _ready():
	super()
	_picker_cursor_mesh = cursor.get_child(0)
	_painter_cursor_mesh = cursor.get_child(1)
	
	_use_selection_resizing = false

func _process(delta: float):
	super(delta)
	if mode == Mode.NONE: return
	
	if _selecting: _perform_action()
	_update_cursors()
	_update_painter_cursor()

func _update_cursors():
	_painter_cursor_mesh.visible = (
		mode == TrixelTool.Mode.PRIMARY or
		mode == TrixelTool.Mode.ALT_PRIMARY
	)
	_picker_cursor_mesh.visible = (mode == TrixelTool.Mode.SECONDARY)

func _update_painter_cursor():
	var material := _painter_cursor_mesh.get_surface_override_material(0)
	material.albedo_color = get_painting_color()
	material.emission = material.albedo_color

func _get_active_color_button() -> ColorButton:
	if Input.is_action_pressed("tool_alt_action"):
		return secondary_color_button
	else:
		return primary_color_button

func get_painting_color() -> Color:
	return _get_active_color_button().color

func _perform_action():
	if mode == TrixelTool.Mode.PRIMARY:
		_paint(false)
	if mode == TrixelTool.Mode.SECONDARY:
		_pick_color()

func on_selection_started():
	if mode == TrixelTool.Mode.ALT_PRIMARY:
		_paint(true)

func _paint(fill : bool):
	# raycaster can occasionally "leak" between trixels
	# prevent painting when that happens
	var facepos = _last_trixel_position + Trile.get_face_normal(_last_trixel_face)
	if trile_editor.trile.get_trixel(facepos): return
	
	trile_editor.paint(_last_trixel_position, _last_trixel_face, get_painting_color(), fill)
	

func _pick_color():
	var button_to_change = _get_active_color_button()
	var color = trile_editor.pick_color(_last_trixel_position, _last_trixel_face)
	button_to_change.color = color


# overloaded functions

func get_debug_text() -> String:
	var pos_text := "none"
	if _aiming_at_trile or _selecting:
		pos_text = ("%s" % _last_trixel_position)
		pos_text = pos_text.substr(1, pos_text.length() - 2).replace(",", " ")
		pos_text += " %s" % Trile.get_face_name(_last_trixel_face)
	return "Hovering: %s" % pos_text

func is_raycast_hit_valid(hit : TrixelRaycaster.Result) -> bool: 
	return hit != null and hit.hit_trixel

func should_offset_raycast_hit(_hit : TrixelRaycaster.Result) -> bool:
	return false
