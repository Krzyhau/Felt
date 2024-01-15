shader_type spatial;
render_mode unshaded;
uniform sampler2D depth_texture : hint_depth_texture;

varying vec3 position;
void vertex() {
	position = VERTEX.xyz;
}

void fragment() {
	ALBEDO = vec3(1.0,1.0,1.0);
	
	float dX = abs(position.x) / 0.5;
	float dY = abs(position.y) / 0.5;
	float dZ = abs(position.z) / 0.5;
	

	float dist = 1.0 - 0.01;
	
	if(max(dX,dY) < dist || max(dY,dZ) < dist || max(dZ,dX) < dist) ALPHA = 0.0f;
	
}
