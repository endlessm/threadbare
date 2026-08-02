/**
 * This is intended to be applied to a CanvasGroup material.
 * SPDX-FileCopyrightText: The Threadbare Authors
 * SPDX-License-Identifier: MPL-2.0
 */
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

/**
 * Grayscale texture with the pattern of the fade.
 */
uniform sampler2D mask_texture : hint_default_white;

/**
 * Grayscale texture with a fabric pattern to multiply the fade mask.
 */
uniform sampler2D fabric_texture : repeat_enable;

/**
 * Scale of the fabric pattern texture, in world units per texel. At 1.0 the
 * fabric is sampled at the same resolution as the world, so one texel of the
 * texture covers exactly one world pixel.
 */
uniform float fabric_scale : hint_range(0.01, 30.0) = 1.0;

/**
 * Fade progress: 0.0 is fully hidden, 1.0 is fully visible
 */
uniform float progress : hint_range(0.0, 1.0) = 0.0;

/**
 * How smooth is the edge of the fade.
 */
uniform float smoothness : hint_range(0.0, 1.0) = 0.1;

/**
 * How long is the edge of the fade.
 */
uniform float burn_size : hint_range(0.0, 1.0) = 0.15;

/**
 * The burn color.
 */
uniform vec4 burn_color : source_color = vec4(1.0, 1.0, 0.58, 1.0);

/**
 * How gray is the existing color (not the burn).
 */
uniform float gray_intensity : hint_range(0.0, 1.0) = 0.0;

/**
 * Position of the fragment in world space, so the fabric pattern is anchored to
 * the world instead of to the screen.
 */
varying vec2 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	// Sample the main texture color of the node
	vec4 main_color = textureLod(screen_texture, SCREEN_UV, 0.0);
	if (main_color.a > 0.0001) {
		main_color.rgb /= main_color.a;
	}

	// A gray version of the main color.
	float gray = dot(main_color.rgb, vec3(0.299, 0.587, 0.114));

	// Sample the mask texture value (taking the red channel)
	float mask_value = texture(mask_texture, UV).r;

	// Sample the fabric pattern texture (taking the red channel). Sampling by
	// world position gives the pattern a fixed size in world units, so it grows
	// when zooming in and scrolls along with the camera. Dividing by the texture
	// size turns world units into UVs, so at fabric_scale 1.0 one texel covers
	// one world pixel.
	vec2 fabric_uv = world_position / (vec2(textureSize(fabric_texture, 0)) * fabric_scale);
	float fabric_value = 1. - texture(fabric_texture, fabric_uv).r;

	// Calculate a clean alpha cutoff based on progress using smoothness.
	float alpha = smoothstep(1.0 - progress, 1.0 - progress + smoothness, mask_value);

	// Calculate the burn, using burn_size.
	float burn = smoothstep(1.0 - progress + burn_size, 1.0 - progress, mask_value);

	vec3 final_color = main_color.rgb;
	// Apply gray:
	final_color = mix(final_color, vec3(gray), gray_intensity);
	// Apply burn:
	if (burn_size != 0.0) {
		final_color = mix(final_color, burn_color.rgb, burn * burn_color.a);
	}
	// Apply the fabric texture.
	alpha *=  2.2 * smoothstep(0., fabric_value, alpha);

	COLOR = vec4(final_color, main_color.a * alpha);
}
