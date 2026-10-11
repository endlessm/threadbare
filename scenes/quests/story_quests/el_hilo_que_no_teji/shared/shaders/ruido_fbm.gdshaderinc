// SPDX-FileCopyrightText: The Threadbare Authors
// SPDX-License-Identifier: MPL-2.0
// Ruido de valor y su suma por capas (fbm), común a las dos nieblas.

float rand(vec2 coord) {
	return fract(sin(dot(coord, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(vec2 coord) {
	vec2 i = floor(coord);
	vec2 f = fract(coord);
	float a = rand(i);
	float b = rand(i + vec2(1.0, 0.0));
	float c = rand(i + vec2(0.0, 1.0));
	float d = rand(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// Cada capa tiene 3.5 veces más frecuencia y la cuarta parte de peso que la anterior.
float fbm(vec2 coord) {
	float value = 0.0;
	float scale = 1.0;
	mat2 rotation = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));

	for (int i = 0; i < 4; i++) {
		value += noise(coord) * scale;
		coord = rotation * coord * 3.5;
		scale *= 0.25;
	}
	return value;
}
