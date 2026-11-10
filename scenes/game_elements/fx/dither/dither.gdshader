// Copyright 2024 KingToot
// SPDX-License-Identifier: CC0-1.0
// https://godotshaders.com/shader/dithering-screen-door-transparency/
shader_type canvas_item;

uniform float intensity: hint_range(0.0, 1.0, 0.05) = 0.0;

const mat4 THRESHOLD_MATRIX = mat4(
		vec4(1.0 / 17.0,  9.0 / 17.0,  3.0 / 17.0, 11.0 / 17.0),
		vec4(13.0 / 17.0,  5.0 / 17.0, 15.0 / 17.0,  7.0 / 17.0),
		vec4(4.0 / 17.0, 12.0 / 17.0,  2.0 / 17.0, 10.0 / 17.0),
		vec4(16.0 / 17.0,  8.0 / 17.0, 14.0 / 17.0,  6.0 / 17.0));

void fragment() {
	vec2 uv = UV / TEXTURE_PIXEL_SIZE;
	COLOR.a *= step(0.0, THRESHOLD_MATRIX[int(uv.x) % 4][int(uv.y) % 4] - intensity);
}
