// SPDX-FileCopyrightText: The Threadbare Authors
// SPDX-License-Identifier: MPL-2.0
// Pulso suave para la placa de presión: tinta el color de la placa hacia
// glow_color de forma cíclica, para que se note "activa".
shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(0.55, 1.0, 0.65, 1.0);
uniform float speed = 2.5;
uniform float strength = 0.4;

void fragment() {
	float pulse = 0.5 + 0.5 * sin(TIME * speed);
	COLOR.rgb = mix(COLOR.rgb, glow_color.rgb, pulse * strength);
}
