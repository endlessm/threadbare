shader_type canvas_item;
render_mode blend_mix;

uniform sampler2D screen_tex_frg_4 : hint_screen_texture;
uniform bool debug = false;

// CircleShape
#include "res://addons/shaderV/rgba/generate_shapes/generateCircle.gdshaderinc"

void fragment() {
	vec3 n_out8p0;
	float n_out8p1;
// CircleShape:8
	vec3 n_in8p1 = vec3(0.50000, 0.50000, 0.00000);
	vec3 n_in8p2 = vec3(1.00000, 1.00000, 0.00000);
	float n_in8p3 = -0.50000;
	float n_in8p4 = 0.50000;
	float n_in8p5 = 0.10000;
	vec3 n_in8p6 = vec3(1.00000, 1.00000, 1.00000);
	float n_in8p7 = 1.00000;
	{
		n_out8p0 = n_in8p6;
		n_out8p1 = _generateCircleFunc(UV.xy, n_in8p1.xy, n_in8p2.xy, n_in8p3, n_in8p4, n_in8p5).a * n_in8p7;
	}


// Input:5
	vec2 n_out5p0 = SCREEN_UV;


// MultiplyAdd:6
	vec2 n_in6p1 = vec2(0.00000, -0.20000);
	vec2 n_out6p0 = (vec2(n_out8p1) * n_in6p1) + n_out5p0;


	vec4 n_out4p0;
// Texture2D:4
	n_out4p0 = texture(screen_tex_frg_4, n_out6p0);


// Output:0
	COLOR.rgb = vec3(n_out4p0.xyz);
	
	if (debug) {
		COLOR.rbg /= COLOR.a;
		// COLOR.rgb /= (1.0-COLOR.a);
	}


}
