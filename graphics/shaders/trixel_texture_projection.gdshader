shader_type spatial;

global uniform bool trixel_draw_emission_mask;

uniform sampler2D TEXTURE : filter_nearest;

uniform bool calculate_projection;
uniform bool inner_faces;
uniform vec3 size;
uniform vec3 offset;

varying flat int face_index;
void vertex() {
	if (calculate_projection){
		vec3 normal = NORMAL;
		
			 if(normal.x < -0.5) face_index = 3;
		else if(normal.x >  0.5) face_index = 1;
		else if(normal.y < -0.5) face_index = 5;
		else if(normal.y >  0.5) face_index = 4;
		else if(normal.z < -0.5) face_index = 2;
		else if(normal.z >  0.5) face_index = 0;
	}
}


void fragment() {
	vec2 uv = UV;
	if (calculate_projection) {
		if (inner_faces) uv.y = 1.0 - uv.y;
		switch (face_index) {
			case 0: uv = vec2(1.0-uv.x, uv.y); break;
			case 2: uv = vec2(uv.x, 1.0-uv.y); break;
			case 4: uv = vec2(1.0-uv.y, 1.0-uv.x); break;
			case 1: case 3: case 5: uv = vec2(uv.y, uv.x); break;
		}
		
		vec2 size2d, pos2d;
		switch(face_index) {
			case 0: size2d = size.xy; pos2d = vec2(offset.x, 1.0-offset.y); break;
			case 1: size2d = size.zy; pos2d = vec2(1.0-offset.z, 1.0-offset.y); break;
			case 2: size2d = size.xy; pos2d = vec2(1.0-offset.x, 1.0-offset.y); break;
			case 3: size2d = size.zy; pos2d = vec2(offset.z, 1.0-offset.y); break;
			case 4: size2d = size.xz; pos2d = vec2(offset.x, offset.z); break;
			case 5: size2d = size.xz; pos2d = vec2(offset.x, 1.0-offset.z); break;
		}
		
		uv = pos2d + (uv - vec2(0.5, 0.5)) * size2d;
		
		uv = (uv + vec2(float(face_index), 0.0)) / vec2(6.0, 1.0);
	}
	
	vec4 color = texture(TEXTURE, uv);
	if(trixel_draw_emission_mask){
		ALBEDO = vec3(color.a);
	}else{
		ALBEDO = vec3(color.xyz);
		EMISSION = ALBEDO * color.a;
	}
	
}

