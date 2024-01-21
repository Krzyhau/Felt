class_name ColorButton extends Button

@onready var main_color_rect : ColorRect = $base_color
@onready var emission_slider : HSlider = $base_color/emission_value

var base_color : Color :
	get: 
		return main_color_rect.color
	set(value):
		value.a = 255
		main_color_rect.color = value

var emission : int :
	get: return emission_slider.value as int
	set(value): emission_slider.value = value

var color : Color : 
	get:
		var c = base_color
		c.a8 = emission
		return c
	set(value):
		base_color = value
		emission = value.a8
