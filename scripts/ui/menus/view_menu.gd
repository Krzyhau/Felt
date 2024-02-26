extends MenuButton

@export var shading_control : ShadingControl
@export var camera : OrbitingCamera

func _ready() -> void:
	var menu := get_popup()
	menu.add_item("Recenter camera", 1)
	menu.add_check_item("Orthographic mode", 2)
	
	menu.add_separator("Rendering mode")
	menu.add_radio_check_item("Shaded", 10)
	menu.add_radio_check_item("Flat", 11)
	menu.add_radio_check_item("Emission Mask", 12)
	menu.add_radio_check_item("Wireframe", 13)
	
	menu.about_to_popup.connect(_on_opening)
	menu.id_pressed.connect(_on_pressed)

func _on_opening():
	var menu := get_popup()
	menu.set_item_checked(menu.get_item_index(2), camera.is_ortho())
	for id in range(10,13):
		var selected := (id - 10 == shading_control.last_set_shading)
		menu.set_item_checked(menu.get_item_index(id), selected)

func _on_pressed(id : int):
	match id:
		1: camera.recenter()
		2: camera.switch_ortho()
		10: _set_shading(ShadingControl.Shading.SHADED)
		11: _set_shading(ShadingControl.Shading.FLAT)
		12: _set_shading(ShadingControl.Shading.FLAT_EMISSION)
		13: _set_shading(ShadingControl.Shading.WIREFRAME)
	
func _set_shading(shading : ShadingControl.Shading):
	shading_control.set_shading(shading)
