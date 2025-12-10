/**
 * Cel shading replacer
 *
 * This shader can replace 3 shades from a sprite that uses the cel-shading technique.
 * It is based on this more generic shader: [link]https://github.com/KoBeWi/Godot-Palette-Swap-Shader/blob/master/addons/PaletteSwapShader/SimplePaletteSwap.gdshader[/link]
 *
 *
 * SPDX-FileCopyrightText: The Threadbare Authors
 * SPDX-License-Identifier: MPL-2.0
 */
shader_type canvas_item;

// Note: key colors are intentionally vec3 because they don't need alpha channel.
// This is unlike the new colors which are of type vec4.
group_uniforms KeyColors;

/**
 * Key color to replace for medium shade. Defaults to full green.
 * [br][br]
 * This is set as an ivec3 with values from 0 to 255 for accuracy.
 */
uniform ivec3 shade_medium_key = ivec3(0, 255, 0);

/**
 * Key color to replace for high shade. Defaults to (5/8, 1, 5/8) or RGB(160, 255, 160).
 */
uniform ivec3 shade_high_key = ivec3(160, 255, 160);

/**
 * Key color to replace for low shade. Defaults to (0, 5/8, 0) or RGB(0, 160, 0).
 */
uniform ivec3 shade_low_key = ivec3(0, 160, 0);

group_uniforms NewColors;

/**
 * The new medium or unshaded color.
 * [br][br]
 * Defaults to yellow emoji-like color.
 */
instance uniform vec4 shade_medium_new : source_color = vec4(0.89, 0.89, 0, 1);

/**
 * The new high or lightened color.
 */
instance uniform vec4 shade_high_new : source_color = vec4(0.91, 0.91, 0.2, 1);

/**
 * The new low or darkened color.
 */
instance uniform vec4 shade_low_new : source_color = vec4(0.71, 0.71, 0, 1);

void fragment() {
	ivec3 colori = ivec3(round(COLOR.rgb * 255.0));
	if (colori == shade_medium_key) {
		COLOR = shade_medium_new;
	}
	else if (colori == shade_high_key) {
		COLOR = shade_high_new;
	}
	else if (colori == shade_low_key) {
		COLOR = shade_low_new;
	}
}
