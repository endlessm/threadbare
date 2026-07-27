/**
 * Particles CanvasGroup outline effect.
 *
 * SPDX-FileCopyrightText: The Threadbare Authors
 * SPDX-License-Identifier: MPL-2.0
 */
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform vec4 outline_color : source_color = vec4(1.0);
uniform float thickness : hint_range(0.0, 10.0) = 2.0;


void fragment() {
	vec4 color = textureLod(screen_texture, SCREEN_UV, 0.0);

	vec4 outline = texture(screen_texture, SCREEN_UV - vec2(thickness, 0.0) * SCREEN_PIXEL_SIZE);
	outline += texture(screen_texture, SCREEN_UV + vec2(thickness, 0.0) * SCREEN_PIXEL_SIZE);
	outline += texture(screen_texture, SCREEN_UV - vec2(0.0, thickness) * SCREEN_PIXEL_SIZE);
	outline += texture(screen_texture, SCREEN_UV + vec2(0.0, thickness) * SCREEN_PIXEL_SIZE);

	outline.rgb = outline_color.rgb;
	outline.a *= outline_color.a;

	if (color.a > 0.0001) {
		color.rgb /= color.a;
	}

	COLOR *= mix(outline, color, color.a);
}
