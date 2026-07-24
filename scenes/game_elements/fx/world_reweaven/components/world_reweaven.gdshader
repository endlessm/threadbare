// SPDX-FileCopyrightText: The Threadbare Authors
// SPDX-License-Identifier: MPL-2.0
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;


// The grayscale texture that dictates the pattern of the fade (e.g., noise, gradient, or shapes)
uniform sampler2D mask_texture : hint_default_white;

uniform sampler2D fabric_texture : repeat_enable;

// Controls the fade progress: 0.0 is fully hidden, 1.0 is fully visible
uniform float progress : hint_range(0.0, 1.0) = 0.0;

// Controls how smooth the edge of the fade is
uniform float smoothness : hint_range(0.0, 1.0) = 0.1;

// Burn effect settings
uniform float burn_size : hint_range(0.0, 1.0) = 0.15;
uniform vec4 burn_color : source_color = vec4(1.0, 1.0, 0.58, 1.0);

uniform float fabric_scale : hint_range(0.0, 10.0) = 4.0;

uniform float gray_intensity : hint_range(0.0, 1.0) = 0.0;


varying vec2 textile_uv;

void vertex() {
	textile_uv.x = UV.x * fabric_scale;
	textile_uv.y = UV.y * fabric_scale;
}

void fragment() {
	// Sample the main texture color of the node
	vec4 main_color = textureLod(screen_texture, SCREEN_UV, 0.0);
	if (main_color.a > 0.0001) {
		main_color.rgb /= main_color.a;
	}

	// Sample the grayscale mask texture value (using the red channel)
	float mask_value = texture(mask_texture, UV).r;

	// Sample the fabric mask texture value.
	vec2 new_uv = UV * 1.0;// * 2.0 + vec2(1.5, 1.5);

	vec2 screen_uv = SCREEN_UV;
	screen_uv.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;


	// float fabric_value = texture(fabric_texture, textile_uv).r;
	float fabric_value = 1. - texture(fabric_texture, screen_uv * fabric_scale).r;

	// Use smoothstep to calculate a clean alpha cutoff based on progress
	// Inverting progress (1.0 - progress) turns a fade-out mask into a fade-in
	float alpha = smoothstep(1.0 - progress, 1.0 - progress + smoothness, mask_value);
	float burn = smoothstep(1.0 - progress + burn_size, 1.0 - progress, mask_value);


	float gray = dot(main_color.rgb, vec3(0.299, 0.587, 0.114));

	vec3 final_color = main_color.rgb;
	// Apply gray:
	final_color = mix(final_color, vec3(gray), gray_intensity);
	// Apply burn:
	if (burn_size != 0.0) {
		final_color = mix(final_color, burn_color.rgb, burn * burn_color.a);
	}
	// vec3 final_color = mix(main_color.rgb, burn_color.rgb, 1. - alpha);

	// Uncomment to not apply the fabric texture.
	// alpha += 0.4 * smoothstep(0., fabric_value, alpha);
	alpha *=  2.2 * smoothstep(0., fabric_value, alpha);

	// Apply the computed alpha transparency to the output color
	COLOR = vec4(final_color, main_color.a * alpha);
}
