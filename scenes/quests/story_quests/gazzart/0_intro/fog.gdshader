shader_type canvas_item;

//Noise texture
uniform sampler2D noise_texture: repeat_enable, filter_nearest;
//Fog density
uniform float density: hint_range(0.0, 1.0) = 0.85;
//Fog spreed
uniform vec2 speed = vec2(0.02, 0.01);

void fragment() {
	//Make the fog move slowly
	vec2 uv = UV + speed * TIME;
	//Sample the noise texture
	float noise = texture(noise_texture, uv).r;
	//Convert noise from (0.0, 1.0) range to (-1.0, 1.0) range
	//then clamp it between 0.0 and 1.0 again
	float fog = clamp(noise * 2.0 - 1.0, 0.0, 1.0);
	//Apply fog effect
	COLOR.a *= fog * density;
	
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
