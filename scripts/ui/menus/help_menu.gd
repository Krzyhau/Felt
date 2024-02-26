extends MenuButton

@export var about_window : Window

func _ready() -> void:
	var menu := get_popup()
	menu.add_item("Join FEZ Community Projects Discord", 1)
	menu.add_item("Open trixel art specification", 2, KEY_F1)
	menu.add_item("Open Felt GitHub repository", 3)
	menu.add_separator()
	menu.add_item("About Felt...", 4)
	
	menu.id_pressed.connect(_on_pressed)

func _on_pressed(id : int) -> void:
	match id:
		1: _open_fez_community_projects_discord()
		2: _open_trixel_art_specification()
		3: _open_felt_repo()
		4: _open_about_window()

func _open_fez_community_projects_discord():
	OS.shell_open("https://discord.gg/wwVB86HhJz")
	
func _open_trixel_art_specification():
	OS.shell_open("https://fezmodding.github.io/wiki/game/trixels")
	
func _open_felt_repo():
	OS.shell_open("https://github.com/Krzyhau/Felt")
	
func _open_about_window():
	about_window.visible = true
