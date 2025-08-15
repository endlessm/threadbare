/**
 * Remember to set the Texture Filter to Nearest on the TileMapLayer to which this is applied!
 * SPDX-FileCopyrightText: The Threadbare Authors
 * SPDX-License-Identifier: MPL-2.0
 */
shader_type canvas_item;

// TODO: Can we get this from SCREEN_PIXEL_SIZE?
/**
 * Viewport size.
 */
uniform vec2 resolution = vec2(1920.0, 1080.0);

/**
 * For best results, use Simplex noise.
 */
uniform sampler2D noise_texture: filter_nearest, repeat_enable;

/**
 * Controls the number of stars in the sky: higher numbers reduce the number of stars.
 */
uniform float sparsity: hint_range(1.0, 100.0, 0.1) = 20.0;

/**
 * Interval between peak brightness of the stars, in seconds.
 */
uniform float flicker_rate: hint_range(1.0, 20.0, 0.1) = 7.0;

/**
 * Key color to replace with starfield.
 */
uniform vec4 chroma_key: source_color = vec4(1.0, 0.0, 0.0, 1.0);

/**
 * Replacement background colour in chroma key area.
 */
uniform vec4 background_color: source_color = vec4(0.086, 0.11, 0.18, 1.0);

uniform vec2 wipe_progress;

// The origin is the upper-left corner of the screen and coordinates ranging from (0.0, 0.0) to viewport size.
varying vec2 screen_pos;

varying vec4 modulate;

void vertex() {
	screen_pos = (CANVAS_MATRIX * MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	modulate = COLOR;
}

void fragment() {
	if (texture(TEXTURE, UV) == chroma_key) {
		vec2 uv = screen_pos / resolution;
		uv.x *= resolution.x / resolution.y;

		float stars = 0.0;

		stars = pow(texture(noise_texture, uv).r, sparsity);
		if (stars < 0.2) {
			stars = 0.0;
		}

		// Oscillates between 1.0 and 2.0
		// TODO: Offset this by screen coordinate so that different stars flicker at different rates?
		float flicker = (sin(TIME * TAU / flicker_rate) + 3.0) / 2.0;

		/* At trough of sine wave, leave brightness untouched.
		 * Otherwise, increases brightness of dimmer stars more than brightness of brighter stars.
		 */
		stars = pow(stars, 1.0 / flicker);

		// TODO: Add a second layer that doesn't stick to the viewport but moves very slowly?
		// TODO: Add some occasional stars that flicker?

		COLOR = background_color + vec4(vec3(stars), 1.0);
		COLOR *= modulate;
	}
}
