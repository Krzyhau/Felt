class_name UIMouseZone extends Control

static var is_mouse_over : bool

func _ready() -> void:
	self.mouse_entered.connect(_on_mouse_entered)
	self.mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered(): is_mouse_over = true
func _on_mouse_exited(): is_mouse_over = false
