// SPDX-FileCopyrightText: The Threadbare Authors
// SPDX-License-Identifier: MPL-2.0
shader_type canvas_item;
// La niebla del Deshilado entrando en la pantalla. Usa el mismo ruido que la
// niebla del nivel 1 (el_hilo_que_no_teji_sequence_puzzle.gdshader), para que
// se reconozca como la misma, pero aquí se amontona en nubes y avanza:
// - por la derecha, hasta un frente (modo lateral), o
// - desde los bordes hacia un punto (modo bordes).
// Se usa sobre un ColorRect a pantalla completa.

#include "res://scenes/quests/story_quests/el_hilo_que_no_teji/shared/shaders/ruido_fbm.gdshaderinc"

uniform vec4 color_niebla : source_color = vec4(0.72, 0.74, 0.8, 1.0);
uniform float opacidad_maxima : hint_range(0.0, 1.0) = 0.9;

uniform bool lateral = false;
// Dónde está el frente, en ancho de pantalla (1.3 = fuera, a la derecha).
uniform float frente = 1.3;

uniform float intensidad : hint_range(0.0, 1.0) = 0.0;
uniform float radio_minimo = 0.35;
uniform vec2 centro = vec2(0.5);

// Al final la niebla lo cubre todo, sin huecos (0 a 1).
uniform float cubrir : hint_range(0.0, 1.0) = 0.0;

// Ancho entre alto de la pantalla, para que las nubes no salgan aplastadas.
const float PROPORCION = 1.78;
const vec2 VIENTO = vec2(-1.0, -0.05);
// Frecuencia de las nubes grandes (bultos), de los jirones y del borde del claro.
const float ESCALA_BULTOS = 1.6;
const vec2 ESCALA_JIRONES = vec2(1.4, 3.2);
const float ESCALA_BORDE_DEL_CLARO = 4.5;
// Lo que avanza cada capa con el viento.
const float VIENTO_BULTOS = 0.05;
const float VIENTO_JIRONES = 0.09;
const vec2 DESFASE_JIRONES = vec2(3.0, 7.0);
const vec2 DESFASE_BORDE_DEL_CLARO = vec2(11.0, 5.0);
// Modo lateral: cuánto deforman los bultos el frente, y qué tan difuso es.
const float DEFORMACION_DEL_FRENTE = 0.45;
const float BULTOS_MEDIOS = 0.6;
const float DIFUSION_DEL_FRENTE = 0.28;
// Modo bordes.
const float DISTANCIA_A_LA_ESQUINA = 1.02;
const float RADIO_DE_REFERENCIA = 0.42;
const float RADIO_INICIAL = 1.3;
const float BORDE_MEDIO_DEL_CLARO = 0.66;
const float DIFUSION_DEL_CLARO = 0.45;
const float INTENSIDAD_DE_ENTRADA = 0.2;
// La densidad va de DENSIDAD_MINIMA (entre jirones) a 1.
const float DENSIDAD_MINIMA = 0.55;
const float OSCURO_DE_LA_NUBE = 0.82;
const float CLARO_DE_LA_NUBE = 1.08;

void fragment() {
	vec2 p = UV * vec2(PROPORCION, 1.0);
	vec2 viento = VIENTO * TIME;

	// Bultos grandes y redondeados: dan el borde de nube.
	float bultos = fbm(p * ESCALA_BULTOS + viento * VIENTO_BULTOS);
	float jirones = fbm(p * ESCALA_JIRONES + viento * VIENTO_JIRONES + DESFASE_JIRONES);

	float masa = 0.0;
	if (lateral) {
		float borde = frente - (bultos - BULTOS_MEDIOS) * DEFORMACION_DEL_FRENTE;
		masa = smoothstep(borde, borde + DIFUSION_DEL_FRENTE, UV.x);
	} else {
		vec2 desde_el_centro = (UV - centro) * vec2(PROPORCION, 1.0);
		float distancia = length(desde_el_centro) / DISTANCIA_A_LA_ESQUINA;
		// Cuanto más pequeño es el claro, menos lo deforman las nubes: así queda
		// centrado en lo que rodea y no se va hacia un lado.
		float claro_relativo = clamp(radio_minimo / RADIO_DE_REFERENCIA, 0.25, 1.0);
		float deformacion = 0.5 * intensidad * claro_relativo;
		// El borde del claro se ondula con nubes pequeñas: las grandes lo
		// empujarían entero hacia un lado y dejaría de estar centrado.
		vec2 ruido_del_borde = p * ESCALA_BORDE_DEL_CLARO + viento * VIENTO_BULTOS;
		float borde_del_claro = fbm(ruido_del_borde + DESFASE_BORDE_DEL_CLARO);
		float inicio = mix(RADIO_INICIAL, radio_minimo, intensidad);
		inicio -= (borde_del_claro - BORDE_MEDIO_DEL_CLARO) * deformacion;
		float entrada = smoothstep(0.0, INTENSIDAD_DE_ENTRADA, intensidad);
		masa = smoothstep(inicio, inicio + DIFUSION_DEL_CLARO, distancia) * entrada;
	}

	float densidad = masa * mix(DENSIDAD_MINIMA, 1.0, smoothstep(0.35, 0.95, jirones));
	densidad = mix(densidad, 1.0, cubrir);

	float brillo = mix(OSCURO_DE_LA_NUBE, CLARO_DE_LA_NUBE, smoothstep(0.4, 1.0, bultos));
	vec3 color = color_niebla.rgb * brillo;
	COLOR = vec4(color, densidad * mix(opacidad_maxima, 1.0, cubrir));
}
