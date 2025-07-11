shader_type canvas_item;

uniform vec2 resolution = vec2(600.0, 400.0);
uniform sampler2D noise_texture: filter_nearest, repeat_enable;
uniform float density: hint_range(1.0, 100.0, 0.1) = 20.0;

uniform sampler2D screen_texture: hint_screen_texture, repeat_disable, filter_nearest;
uniform vec4 chroma_key: source_color;
uniform vec2 camera_pos;

// COLOR is input too!
void fragment() {
	if (length(textureLod(screen_texture, SCREEN_UV, 0.0) - chroma_key) < 0.1) {
		vec2 uv = UV;
		uv.x *= resolution.x / resolution.y;
		float stars = 0.0;
		vec2 offset = vec2(0.0); // TODO: add a second layer that moves at a slightly different offset
		stars += step(0.2, pow(texture(noise_texture, uv + offset).r, density));
		COLOR = vec4(vec3(stars), 1.0);
	} else {
		COLOR.a = 0.0;
	}
}
