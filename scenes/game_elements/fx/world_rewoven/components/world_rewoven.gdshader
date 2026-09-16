/**
 * This is intended to be applied to a CanvasGroup material.
 * SPDX-FileCopyrightText: The Threadbare Authors
 * SPDX-License-Identifier: MPL-2.0
 */
shader_type canvas_item;
// Not unshaded: the engine only applies the color of a CanvasModulate, and 2D
// lights, to canvas items that are not unshaded. Without this, a node using this
// shader stays untinted while the rest of the scene is tinted.

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

/**
 * Grayscale texture with the pattern of the fade.
 */
uniform sampler2D mask_texture : hint_default_white, repeat_disable;

/**
 * Origin, in world units, of the region the fade mask is stretched across.
 */
uniform vec2 mask_origin = vec2(0.0);

/**
 * Size, in world units, of the region the fade mask is stretched across. Set
 * this together with [member mask_origin] to the bounds of the affected area,
 * so the mask spans it exactly once whether this material is applied to a
 * [CanvasGroup] or to a single [CanvasItem] such as a [TileMapLayer].
 */
uniform vec2 mask_size = vec2(1920.0, 1080.0);

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
 * Wether to target a CanvasGroup node or a single CanvasItem.
 */
uniform bool target_canvas_group = true;

/**
 * How smooth is the edge of the fade.
 */
uniform float smoothness : hint_range(0.0, 1.0) = 0.1;

/**
 * How long is the edge of the fade.
 */
uniform float burn_size : hint_range(0.0, 1.0) = 0.15;

/**
 * The burn color. Brighter than white, so that it reads as light.
 */
uniform vec4 burn_color : source_color = vec4(1.353, 1.353, 0.777, 1.0);

/**
 * Color of the [CanvasModulate] of the scene, if there is one. The burn is
 * divided by it, so that the multiplication the engine does afterwards cancels
 * out and the burn keeps its full brightness, as if it was made of light.
 */
uniform vec4 canvas_modulate : source_color = vec4(1.0, 1.0, 1.0, 1.0);

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
	vec4 main_color;
	if (target_canvas_group) {
		main_color = textureLod(screen_texture, SCREEN_UV, 0.0);
		if (main_color.a > 0.0001) {
			main_color.rgb /= main_color.a;
		}
	} else {
		// COLOR already holds the texture multiplied by the node's modulate, so
		// sampling TEXTURE again here would apply the texture twice and darken
		// the result.
		main_color = COLOR;
	}

	// A gray version of the main color.
	float gray = dot(main_color.rgb, vec3(0.299, 0.587, 0.114));

	// Sample the mask texture value (taking the red channel). Using world
	// position instead of UV, because on a TileMapLayer UV is the coordinate
	// into the tileset atlas of each individual tile, not a coordinate across
	// the whole node, which would repeat the mask on every tile.
	vec2 mask_uv = (world_position - mask_origin) / mask_size;
	float mask_value = texture(mask_texture, mask_uv).r;

	// Sample the fabric pattern texture (taking the red channel). Sampling by
	// world position gives the pattern a fixed size in world units, so it grows
	// when zooming in and scrolls along with the camera. Dividing by the texture
	// size turns world units into UVs, so at fabric_scale 1.0 one texel covers
	// one world pixel.
	vec2 fabric_uv = world_position / (vec2(textureSize(fabric_texture, 0)) * fabric_scale);
	float fabric_value = 1. - texture(fabric_texture, fabric_uv).r;

	// Sweep the threshold slightly past the 0.0 to 1.0 range of the mask, by the
	// width of the widest edge, so that progress 0.0 hides every pixel and
	// progress 1.0 shows every pixel, whatever the mask texture contains. In
	// between, the mask still drives the shape of the transition.
	float edge_size = max(smoothness, burn_size);
	float threshold = 1.0 - progress * (1.0 + edge_size);

	// Calculate a clean alpha cutoff based on progress using smoothness.
	float alpha = smoothstep(threshold, threshold + smoothness, mask_value);

	// Calculate the burn, using burn_size.
	float burn = smoothstep(threshold + burn_size, threshold, mask_value);

	vec3 final_color = main_color.rgb;
	// Apply gray:
	final_color = mix(final_color, vec3(gray), gray_intensity);
	// Apply burn, undoing the canvas modulate so that it looks unshaded:
	if (burn_size != 0.0) {
		vec3 unshaded_burn = burn_color.rgb / max(canvas_modulate.rgb, vec3(0.001));
		final_color = mix(final_color, unshaded_burn, burn * burn_color.a);
	}
	// Apply the fabric texture.
	alpha *=  2.2 * smoothstep(0., fabric_value, alpha);

	COLOR = vec4(final_color, main_color.a * alpha);
}
