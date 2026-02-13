shader_type canvas_item;
render_mode blend_sub;

uniform sampler2D shadow_texture: repeat_enable, filter_nearest;
uniform vec2 speed = vec2(0.02,0.01);
uniform float intensity: hint_range(0.0, 1.0) = 0.2;
uniform float density: hint_range(0.0, 10.0) = 1.0;

void fragment() {
	vec2 uv = UV + speed * TIME;
	float shadow = texture(shadow_texture, uv).r;
	shadow = clamp(shadow * density - density / 2.0, 0.0, 0.1 * intensity);
	COLOR.a *= shadow;
}
