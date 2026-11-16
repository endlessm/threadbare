// SPDX-FileCopyrightText: The Threadbare Authors
// SPDX-License-Identifier: MPL-2.0
shader_type canvas_item;

uniform sampler2D cloud_texture;
uniform sampler2D density_texture;

uniform vec2 offset;

uniform float scale: hint_range(0.1, 10.0, 0.1) = 1.0;

varying vec2 world_pos;

void vertex() {
	// Transform it into world coordinates
	world_pos = (MODEL_MATRIX * vec4(1.0, 1.0, 0.0, 1.0)).xy;
}

vec2 to_uv_coordinates(vec2 position, sampler2D tex) {
	ivec2 tex_size = textureSize(tex, 0);
	return vec2(position.x / float(tex_size.x), position.y / float(tex_size.y));
}

void fragment() {
	COLOR = texture(cloud_texture, fract((UV + to_uv_coordinates(world_pos, cloud_texture) + to_uv_coordinates(offset, cloud_texture)) * scale));
}
