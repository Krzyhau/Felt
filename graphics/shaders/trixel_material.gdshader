shader_type spatial;

global uniform bool trixel_draw_emission_mask;

uniform sampler2D TEXTURE : filter_nearest, source_color;

void fragment() {
	vec2 uv = UV;

	vec4 color = texture(TEXTURE, uv);
	if(trixel_draw_emission_mask){
		ALBEDO = vec3(color.a);
	}else{
		ALBEDO = vec3(color.xyz);
		EMISSION = ALBEDO * color.a;
	}
	
}

