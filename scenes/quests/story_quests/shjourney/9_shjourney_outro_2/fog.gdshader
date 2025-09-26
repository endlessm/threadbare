shader_type canvas_item;

uniform sampler2D noise_texture: repeat_enable, filter_nearest;

uniform float density: hint_range(0.0,1.0) = 0.25;

uniform vec2 speed = vec2(0.02,0.01);

void fragment() {
	vec2 uv = UV + speed * TIME;
	float noise = texture(noise_texture, uv).r;
	float fog = clamp(noise * 2.0 - 1.0,0.0,1.0);
	COLOR.a *= fog * density;
	 
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
