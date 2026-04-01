/**
 * Ripple effect
 *
 * This shader expects the CanvasItem to be a gradient asset that goes from white to transparent.
 * It adjusts the alpha to create a ripple effect of a certain width.
 *
 * SPDX-FileCopyrightText: The Threadbare Authors
 * SPDX-License-Identifier: MPL-2.0
 */
shader_type canvas_item;
render_mode blend_add;

/**
 * How smooth or sharp are the ripples.
 */
uniform float ease: hint_range(0.0, 2.0) = 2.0;

/**
 * This is perceived as the amount of ripples.
 */
uniform float modulo_width: hint_range(0.0, 1.0) = 0.2;

/**
 * The ripple width.
 */
uniform float width: hint_range(0.0, 1.0) = 0.4;

/**
 * The ripple speed.
 */
uniform float speed: hint_range(0.0, 2.0) = 0.2;

void fragment() {
	float sdf_alpha = mod(TIME * speed + COLOR.a, modulo_width);
	float front_ease = smoothstep(0, ease, sdf_alpha);
	float easeAmount = front_ease * modulo_width;
	float brightness = COLOR.a - sdf_alpha + easeAmount;

	COLOR.a = smoothstep(1.0 - width, width+(1.0 - width), brightness);
}
