// SPDX-FileCopyrightText: The Threadbare Authors
// SPDX-License-Identifier: MPL-2.0
shader_type canvas_item;

#include "res://scenes/quests/story_quests/el_hilo_que_no_teji/shared/shaders/ruido_fbm.gdshaderinc"

// Niebla estirada en filamentos que el viento arrastra hacia la izquierda.
uniform vec4 fog_color : source_color = vec4(0.45, 0.48, 0.52, 0.35);
uniform float speed : hint_range(0.0, 1.0) = 0.12;
uniform float detail_steps : hint_range(1.0, 6.0) = 4.0;
uniform float thread_shredding : hint_range(0.1, 3.0) = 1.8;
uniform float density : hint_range(0.1, 5.0) = 0.5;

uniform vec2 wind_direction = vec2(-1.0, -0.05);
uniform float stretch_factor : hint_range(1.0, 10.0) = 5.0;

// Píxeles del mundo a coordenadas del ruido.
const float WORLD_TO_NOISE = 0.002;
// La segunda capa es más fina, más lenta y está desplazada.
const float SECOND_LAYER_SCALE = 1.3;
const float SECOND_LAYER_SPEED = 0.7;
const vec2 SECOND_LAYER_OFFSET = vec2(0.2, 0.5);
const float LAYERS_GAIN = 1.6;
// Por debajo de FOG_START no hay niebla; por encima de FOG_FULL, la hay entera.
const float FOG_START = 0.55;
const float FOG_FULL = 0.75;

varying vec2 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 stretch = vec2(stretch_factor, 1.0);
	vec2 base_uv = (world_position * WORLD_TO_NOISE * density) / stretch;

	vec2 wind_1 = wind_direction * (TIME * speed);
	vec2 wind_2 = wind_direction * (TIME * speed * SECOND_LAYER_SPEED) + SECOND_LAYER_OFFSET;

	float layer1 = fbm(base_uv + wind_1);
	float layer2 = fbm(base_uv * SECOND_LAYER_SCALE + wind_2);

	// El contraste alto deja pasillos transparentes entre las rocas.
	float final_shredded_fog = smoothstep(FOG_START, FOG_FULL, layer1 * layer2 * LAYERS_GAIN);

	final_shredded_fog = pow(final_shredded_fog, thread_shredding);

	float alpha_mask = final_shredded_fog * fog_color.a;

	COLOR = vec4(fog_color.rgb, alpha_mask);
}
