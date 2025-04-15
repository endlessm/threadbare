// SPDX-FileCopyrightText: The Threadbare Authors
// SPDX-License-Identifier: MPL-2.0
shader_type canvas_item;

uniform sampler2D wind_affect_curve;
uniform float phase_period : hint_range(1.0, 10000.0, 10.0) = 1000.0;
uniform sampler2D phase_noise;
uniform float max_wind_speed : hint_range(0.0, 50.0, 0.1) = 5.0;
uniform float max_wind_intensity : hint_range(0.0, 10.0, 0.1) = 2.0;

varying vec2 world_pos;

void vertex() {
   // Transform it into world coordinates
   world_pos = (MODEL_MATRIX * vec4(1.0, 1.0, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 noise_position = world_pos;
	float noise_value = texture(phase_noise, noise_position / phase_period).x;
	float wind_phase = noise_value * 100.0;
	float wind_speed = noise_value * max_wind_speed;
	float max_offset = sin(TIME * wind_speed + wind_phase) * max_wind_intensity;
	float curve_value = texture(wind_affect_curve, vec2((1.0 - UV.y), 0.0)).x;
	COLOR = texture(TEXTURE, UV + vec2(max_offset * (1.0 - UV.y) * curve_value * 0.02, 0.0));
}
