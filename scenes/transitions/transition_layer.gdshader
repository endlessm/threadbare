// SPDX-FileCopyrightText: 2025 The Threadbare Authors
// SPDX-License-Identifier: MPL-2.0
shader_type canvas_item;
render_mode unshaded;

uniform float cutoff : hint_range(0.0, 1.0);
uniform float smooth_size : hint_range(0.0, 1.0);
uniform sampler2D mask : hint_default_white;


void fragment() {
	float value = texture(mask, UV).r;
	float alpha = smoothstep(cutoff, cutoff + smooth_size, value + smooth_size - value * smooth_size);
	COLOR = vec4(COLOR.rgb, alpha);
}
