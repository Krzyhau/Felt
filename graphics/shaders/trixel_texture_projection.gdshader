shader_type spatial;

uniform sampler2D TEXTURE : filter_nearest;

void fragment() {
	ALBEDO = vec3(texture(TEXTURE, UV).xyz);
}

