/**
 * Drop shadow shader
 *
 * This shader drops a shadow. Intended for button textures
 * in the input HUD.
 *
 * SPDX-FileCopyrightText: The Threadbare Authors
 * SPDX-License-Identifier: MPL-2.0
 */
shader_type canvas_item;

uniform vec2 offset = vec2(2.0, 2.0);
uniform vec4 shadow_color: source_color = vec4(0.0, 0.0, 0.0, 1.0);

varying vec4 modulate;

void vertex() {
	modulate = COLOR;
}

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	vec4 shadow = texture(TEXTURE, UV - offset * TEXTURE_PIXEL_SIZE);
	shadow.rgb = shadow_color.rgb;
	shadow.a *= shadow_color.a;
	COLOR = mix(shadow, modulate * color, color.a);
}
