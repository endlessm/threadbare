shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float saturation : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV);

	float gray = dot(
		screen_color.rgb,
		vec3(0.299, 0.587, 0.114)
	);

	vec3 grayscale = vec3(gray);

	vec3 final_color = mix(
		grayscale,
		screen_color.rgb,
		saturation
	);

	COLOR = vec4(final_color, screen_color.a);
}