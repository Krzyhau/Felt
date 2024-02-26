extends Window

func _ready() -> void:
	go_back_requested.connect(_close_window)
	close_requested.connect(_close_window)

func _close_window():
	visible = false
