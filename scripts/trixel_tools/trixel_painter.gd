class_name TrixelPainter extends TrixelTool

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
	
	if _selecting: _paint()
	_update_cursors()
	_update_painter_cursor()

func _update_cursors():
	_painter_cursor_mesh.visible = (mode == TrixelTool.Mode.PRIMARY)
	_picker_cursor_mesh.visible = (mode == TrixelTool.Mode.SECONDARY)

func _update_painter_cursor():
	var material := _painter_cursor_mesh.get_surface_override_material(0)
	const color := Color.RED
	material.albedo_color = color
	material.emission = material.albedo_color

func _paint():
	# raycaster can occasionally "leak" between trixels
	# prevent painting when that happens
	var facepos = _last_trixel_position + Trile.get_face_normal(_last_trixel_face)
	if trile_editor.trile.get_trixel(facepos): return
	
	trile_editor.paint(_last_trixel_position, _last_trixel_face, Color.RED)



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
