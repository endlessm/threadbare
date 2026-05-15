/**
 * Cel shading replacer
 *
 * This shader replaces each color that appears in the key_colors palette,
 * with the one of same index in the new_colors palette.
 *
 * It is copied from: [link]https://github.com/KoBeWi/Godot-Palette-Swap-Shader/blob/master/addons/PaletteSwapShader/SimplePaletteSwap.gdshader[/link]
 *
 * SPDX-FileCopyrightText: The Threadbare Authors
 * SPDX-License-Identifier: MPL-2.0
 */
shader_type canvas_item;

uniform int color_count;
uniform ivec3[256] key_colors;
uniform vec3[256] new_colors;

void fragment() {
	ivec3 colori = ivec3(round(COLOR.rgb * 255.0));
	for (int i = 0; i < color_count; i++) {
		if (colori == key_colors[i]) {
			COLOR.rgb = new_colors[i];
			break;
		}
	}
}
