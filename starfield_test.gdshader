shader_type canvas_item;

uniform vec2 resolution = vec2(600.0, 400.0);
uniform sampler2D noise_texture: filter_nearest, repeat_enable;
uniform float density: hint_range(1.0, 100.0, 0.1) = 20.0;

uniform sampler2D screen_texture: hint_screen_texture, repeat_disable, filter_nearest;
uniform vec4 chroma_key: source_color;

// In canvas space the origin is the upper-left corner of the screen and coordinates ranging from (0.0, 0.0) to viewport size.
varying vec2 screen_pos;

void vertex() {
	screen_pos = (CANVAS_MATRIX * MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	if (length(textureLod(TEXTURE, UV, 0.0) - chroma_key) < 0.001) {
		vec2 uv = screen_pos / resolution;
		float stars = 0.0;
		vec2 offset = vec2(0.0); // TODO: add a second layer that moves at a slightly different offset
		stars += step(0.2, pow(texture(noise_texture, uv + offset).r, density));
		COLOR = vec4(vec3(stars), 1.0);
	} /* else leave COLOR alone */
}
