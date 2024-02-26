extends Window

@export var version_text : Label

func _ready() -> void:
	go_back_requested.connect(_close_window)
	close_requested.connect(_close_window)
	
	version_text.text = "Version "
	version_text.text += ProjectSettings.get_setting("application/config/version")

func _close_window():
	visible = false
