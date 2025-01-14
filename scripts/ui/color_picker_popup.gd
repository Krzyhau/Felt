class_name ColorPickerPopup extends Panel

@export var primary_color_button : ColorButton
@export var secondary_color_button : ColorButton

@onready var color_picker : ColorPicker = $arrangement/color_picker
@onready var emission_slider : HSlider = $arrangement/emission_controls/slider
@onready var emission_value : SpinBox = $arrangement/emission_controls/value
@onready var recent_color_buttons : Container = $arrangement/color_buttons

var _active_button : ColorButton

func _ready() -> void:
	color_picker.color_changed.connect(_on_color_changed)
	
	emission_slider.value_changed.connect(_on_emmission_changed)
	emission_value.value_changed.connect(_on_emmission_changed)
	
	primary_color_button.toggled.connect(func(state:bool): 
		_on_color_button_pressed(primary_color_button, state)
	)
	secondary_color_button.toggled.connect(func(state:bool): 
		_on_color_button_pressed(secondary_color_button, state)
	)
	
	for i in range(recent_color_buttons.get_child_count()):
		var button := recent_color_buttons.get_child(i) as ColorButton
		button.pressed.connect(func(): _on_recent_color_button_pressed(button))
	
	get_viewport().gui_focus_changed.connect(_on_focus_changed)

func _on_color_button_pressed(button : ColorButton, state : bool):
	if not state:
		self.visible = false
		return
	
	_active_button = button
	self.visible = true
	var button_corner = button.global_position + button.size
	self.global_position = button_corner + Vector2(8, -self.size.y)
	
	color_picker.color = button.base_color
	emission_value.value = button.emission
	
	# button group doesn't work and I have absolutely no idea why
	if button == primary_color_button: 
		secondary_color_button.set_pressed_no_signal(false)
	if button == secondary_color_button: 
		primary_color_button.set_pressed_no_signal(false)

func _on_recent_color_button_pressed(button: ColorButton):
	_active_button.color = button.color

func _on_focus_changed(control:Control) -> void:
	var self_has_focus = self.is_ancestor_of(control)
	var buttons_have_focus = (control == primary_color_button) or (control == secondary_color_button)
	if not self_has_focus and not buttons_have_focus:
		self.visible = false
		primary_color_button.set_pressed_no_signal(false)
		secondary_color_button.set_pressed_no_signal(false)
		_push_recent_color()

func _on_color_changed(new_value : Color):
	if _active_button != null:
		_active_button.base_color = new_value

func _on_emmission_changed(new_value : float):
	emission_slider.set_value_no_signal(new_value)
	emission_value.set_value_no_signal(new_value)
	
	if _active_button != null:
		_active_button.emission = new_value as int

func _push_recent_color():
	var color_to_add := color_picker.color
	color_to_add.a8 = emission_value.value as int
	
	var recent_buttons_count := recent_color_buttons.get_child_count()
	for i in range(recent_buttons_count):
		var button := recent_color_buttons.get_child(i) as ColorButton
		if button.color == color_to_add: return
		
	for i in range(recent_buttons_count - 1, 0, -1):
		var current_button := recent_color_buttons.get_child(i) as ColorButton
		var last_button := recent_color_buttons.get_child(i-1) as ColorButton
		current_button.color = last_button.color
	
	var first := recent_color_buttons.get_child(0) as ColorButton
	first.color = color_to_add
