class_name ExitDiscardDialog extends Window

@export var save_button : Button
@export var dont_save_button : Button
@export var cancel_button : Button

signal save_requested
signal save_ignored
signal cancelled

func _ready() -> void:
	save_button.pressed.connect(_request_save)
	dont_save_button.pressed.connect(_ignore_save)
	cancel_button.pressed.connect(_cancel)
	close_requested.connect(_cancel)
	go_back_requested.connect(_cancel)

func _request_save():
	visible = false
	save_requested.emit()
	
func _ignore_save():
	visible = false
	save_ignored.emit()
	
func _cancel():
	visible = false
	cancelled.emit()
