// SPDX-FileCopyrightText: The Threadbare Authors
// SPDX-License-Identifier: MPL-2.0
shader_type canvas_item;
render_mode blend_add;

uniform float ease;
uniform float modulo_width;

uniform float width;
uniform float ripple_speed;

void fragment() {
	float sdf_alpha = mod(TIME * ripple_speed + COLOR.a, modulo_width);
	float front_ease = smoothstep(0, ease, sdf_alpha);
	float easeAmount = front_ease * modulo_width;
	float brightness = COLOR.a - sdf_alpha + easeAmount;

	COLOR.a = smoothstep(1.0 - width, width+(1.0 - width), brightness);
}
