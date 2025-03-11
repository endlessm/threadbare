shader_type canvas_item;

uniform sampler2D screen_texture: hint_screen_texture;
uniform sampler2D deform_texture: hint_default_black; //repeat_disable, filter_nearest;

uniform vec2 center;
uniform float force : hint_range(0,1, 0.01);
uniform float size : hint_range(0,1,0.01);
uniform float thick : hint_range(0,1,0.01);
uniform float range : hint_range(0,1.0,0.01);
uniform bool debug = false;

vec2 _sphericalUV(vec2 _spherical_uv, vec2 _spherical_position_vect, vec2 _spherical_radius_vect, vec2 _spherical_spin_vect, vec2 _spherical_local_position_vect){
	vec2 _temp_p = (_spherical_uv - _spherical_position_vect) * 2.0;
	float _temp_rad = length((_temp_p - _spherical_local_position_vect) * _spherical_radius_vect) + 0.0001;
	float _temp_f = (1.0 - sqrt(1.0 - _temp_rad)) / _temp_rad;
	return mod(vec2((_temp_p.x * 0.5 * _temp_f + _spherical_spin_vect.x) + 0.5,
					(_temp_p.y * 0.5 * _temp_f + _spherical_spin_vect.y) + 0.5), vec2(1.0));
}

void fragment() {
	vec2 scaledUV = UV;
	float mask = (1.0 - smoothstep(size,size+0.1, length(scaledUV - center)))
	 * smoothstep(size-thick-0.01, size-thick+0.4, length(scaledUV-center));
	vec2 disp = normalize(scaledUV - center) * force * mask;// * clamp(range-size,0.0,100.0);
	if(disp == vec2(0.0,0.0)){
		COLOR = texture(screen_texture, SCREEN_UV);
	}
	else
		if (debug) {
			COLOR = vec4(disp * 100., vec2(0.0, 1.0));
		} else {
			COLOR = texture(screen_texture, SCREEN_UV-disp);
		}


    // float aspect_ratio = SCREEN_PIXEL_SIZE.y/SCREEN_PIXEL_SIZE.x;
	// vec4 deform_color = texture(deform_texture, UV);
	// vec4 color = texture(screen_texture, SCREEN_UV);
	//vec4 color = texture(screen_texture, SCREEN_UV) + deform_color;
	// vec4 color = vec4(SCREEN_UV.r, SCREEN_UV.g, 0.0, 1.0);
	// vec4 color = texture(screen_texture, SCREEN_UV + deform_color.rg);
	// vec4 color = texture(deform_texture, UV);
	// vec4 color = texture(screen_texture, SCREEN_UV + foo.rg);
	// COLOR = vec4(UV.r, color.r, color.b, 1);
	// COLOR = color;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
