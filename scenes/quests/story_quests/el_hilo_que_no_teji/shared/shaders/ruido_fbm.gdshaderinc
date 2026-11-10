// SPDX-FileCopyrightText: The Threadbare Authors
// SPDX-License-Identifier: MPL-2.0
// Ruido de valor y su suma por capas (fbm), común a las dos nieblas.

// Todo en alta precisión: en la web y en GPUs de móvil los decimales son de media precisión
// por defecto, y con coordenadas grandes el ruido se partía en franjas.
// El hash no usa sin(): sin() da resultados distintos según la GPU y es más lento.
float rand(highp vec2 coord) {
	highp vec3 p3 = fract(vec3(coord.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float noise(highp vec2 coord) {
	highp vec2 i = floor(coord);
	highp vec2 f = fract(coord);
	highp float a = rand(i);
	highp float b = rand(i + vec2(1.0, 0.0));
	highp float c = rand(i + vec2(0.0, 1.0));
	highp float d = rand(i + vec2(1.0, 1.0));
	highp vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// Cada capa tiene 3.5 veces más frecuencia y la cuarta parte de peso que la anterior.
// Una cuarta capa pesaría solo el 1.6 % y costaría la cuarta parte del shader en cada píxel.
const int CAPAS_DEL_FBM = 3;

float fbm(highp vec2 coord) {
	highp float value = 0.0;
	highp float scale = 1.0;
	highp mat2 rotation = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));

	for (int i = 0; i < CAPAS_DEL_FBM; i++) {
		value += noise(coord) * scale;
		coord = rotation * coord * 3.5;
		scale *= 0.25;
	}
	return value;
}
