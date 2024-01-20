class_name TrixelPlacer extends "res://scripts/trixel_tool.gd"

func _process(delta: float) -> void:
	super(delta)
	if mode == Mode.NONE: return
	
	_update_placer_cursor()
	

func _update_placer_cursor():
	var material : StandardMaterial3D = cursor.get_surface_override_material(0)
	const color_placing := Color(0.0,0.0,1.0,0.5)
	const color_erasing := Color(1.0,0.0,0.0,0.5)
	material.albedo_color = color_placing if mode == Mode.PRIMARY else color_erasing
	material.emission = material.albedo_color



# overloaded functions

func get_debug_text() -> String:
	var pos_text := "none"
	if _aiming_at_trile or _selecting:
		pos_text = ("%s" % _last_trixel_position)
		pos_text = pos_text.substr(1, pos_text.length() - 2).replace(",", " ")
	return "Hovering: %s" % pos_text

func is_raycast_hit_valid(hit : TrixelRaycaster.Result) -> bool: 
	return hit != null

func should_offset_raycast_hit(hit : TrixelRaycaster.Result) -> bool: 
	var is_placer_tool : bool = mode == TrixelPlacer.Mode.PRIMARY
	var normal = Trile.get_face_normal(hit.face)
	var offset_within_bounds := trile_editor.trile.contains_trixel_pos(hit.position + normal)
	var within_bounds := trile_editor.trile.contains_trixel_pos(hit.position)
	
	return (is_placer_tool and offset_within_bounds) or not within_bounds
