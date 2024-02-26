class_name ShadingControl extends Node

enum Shading {SHADED, FLAT, FLAT_EMISSION, WIREFRAME}

var last_set_shading : Shading

@export var environment : WorldEnvironment

func _ready() -> void:
	RenderingServer.set_debug_generate_wireframes(true)
	set_shading(Shading.SHADED)

func set_shading(shading : Shading):
	var debug_draw_mode : Viewport.DebugDraw;
	
	match shading:
		Shading.SHADED: debug_draw_mode = Viewport.DEBUG_DRAW_DISABLED
		Shading.FLAT: debug_draw_mode = Viewport.DEBUG_DRAW_UNSHADED
		Shading.FLAT_EMISSION: debug_draw_mode = Viewport.DEBUG_DRAW_UNSHADED
		Shading.WIREFRAME: debug_draw_mode = Viewport.DEBUG_DRAW_WIREFRAME
		
	get_viewport().debug_draw = debug_draw_mode

	RenderingServer.global_shader_parameter_set(
		"trixel_draw_emission_mask",
		shading == Shading.FLAT_EMISSION
	)
	
	last_set_shading = shading
