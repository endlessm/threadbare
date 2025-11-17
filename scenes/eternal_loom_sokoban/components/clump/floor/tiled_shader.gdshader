// SPDX-FileCopyrightText: The Threadbare Authors
// SPDX-License-Identifier: MPL-2.0
shader_type canvas_item;

uniform vec3 dark_overlay : source_color = vec3(0.8);
uniform float grid_size = 32;

varying vec2 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0, 1.0)).xy;
	world_position /= grid_size;
}

void fragment() {
	float weight = floor(world_position.x);
	weight += floor(world_position.y);
	weight = float(int(weight) % 2);
	COLOR = mix(COLOR, vec4(COLOR.rgb * dark_overlay, COLOR.a), weight);
}
