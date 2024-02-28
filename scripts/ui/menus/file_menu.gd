extends MenuButton

@export var session_controller : FeltSession

@warning_ignore("int_as_enum_without_cast")
@warning_ignore("int_as_enum_without_match")
func _ready() -> void:
	var menu := get_popup()
	menu.add_item("New Art Object", 1, KEY_MASK_CTRL | KEY_N)
	menu.add_item("New Trile Set", 2, KEY_MASK_CTRL | KEY_MASK_ALT | KEY_N)
	menu.add_separator()
	menu.add_item("Open...", 3, KEY_MASK_CTRL | KEY_O)
	menu.add_item("Save", 4, KEY_MASK_CTRL | KEY_S)
	menu.add_item("Save as...", 5, KEY_MASK_CTRL | KEY_MASK_ALT | KEY_S)
	menu.add_separator()
	menu.add_item("Quit", 6, KEY_MASK_CTRL | KEY_Q)
	
	menu.id_pressed.connect(_on_pressed)

func _on_pressed(id : int) -> void:
	match id:
		1: _new_art_object()
		2: _new_trile_set()
		3: _open_file()
		4: _save_current()
		5: _save_current_as()
		6: _quit()

func _new_art_object():
	pass
	
func _new_trile_set():
	pass
	
func _open_file():
	session_controller.try_open_file()
	
func _save_current():
	pass
	
func _save_current_as():
	pass
	
func _quit():
	session_controller.try_quit()
