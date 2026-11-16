/**
 * SPDX-FileCopyrightText: The Threadbare Authors
 * SPDX-License-Identifier: MPL-2.0
 */
shader_type canvas_item;

/**
 * The shader is set to subtract because it's a shadow.
 */
render_mode blend_sub;

/**
 * Use a Simplex noise for a dynamic texture. Or provide your own grayscale tileable texture!
 */
uniform sampler2D shadow_texture: filter_nearest, repeat_enable;

/**
 * How much covered by clouds is the sky.
 * - 0: Zero shadows.
 * - 1: All dark.
 * This parameter could be animated!
 */
uniform float amount: hint_range(0.0, 1.0) = 0.35;

/**
 * How much contrast. Or how much defined is the shadow silhouette.
 */
uniform float contrast: hint_range(0.0, 50.0) = 25.0;

/**
 * Animate the clouds.
 * A 2/3 velocity emphasizes the world perspective.
 */
uniform vec2 speed = vec2(0.015,0.01);

/**
 * How much alpha. Keep this subtle.
 */
uniform float alpha: hint_range(0.0, 1.0) = 0.1;


void fragment() {
	// Displace the UV to animate the shadow.
	vec2 uv = UV + speed * TIME;

	float shadow = texture(shadow_texture, uv).r;

	// Add amount value.
	shadow = amount - shadow;

	// Apply contrast to define the shadow silhouette.
	// The result may be outside of the 0-1 range.
	shadow = shadow * contrast + 0.5;

	// Normalize the values to land between 0 and 1 again
	// after applying contrast.
	shadow = clamp(shadow, 0.0, 1.0);

	// Apply alpha.
	COLOR.a = alpha * shadow;
}
