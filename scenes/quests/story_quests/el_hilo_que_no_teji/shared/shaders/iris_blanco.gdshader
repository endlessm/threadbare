// SPDX-FileCopyrightText: The Threadbare Authors
// SPDX-License-Identifier: MPL-2.0
shader_type canvas_item;
// Un círculo blanco que crece desde "centro" hasta cubrir la pantalla.

uniform vec2 centro = vec2(0.0);
uniform vec2 tamano = vec2(1920.0, 1080.0);
uniform float radio = 0.0;
uniform float borde = 90.0;

void fragment() {
	float distancia = distance(UV * tamano, centro);
	COLOR = vec4(1.0, 1.0, 1.0, 1.0 - smoothstep(radio - borde, radio, distancia));
}
