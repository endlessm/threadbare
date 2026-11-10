// SPDX-FileCopyrightText: The Threadbare Authors
// SPDX-License-Identifier: MPL-2.0
shader_type canvas_item;
// Oscuridad de pesadilla que entra por los bordes de la pantalla: no es un
// marco parejo, sino manchas y lenguas irregulares que se mueven, avanzan y
// retroceden, y laten. Se usa sobre un ColorRect a pantalla completa.

uniform float intensidad : hint_range(0.0, 1.0) = 0.0;
uniform vec4 color_borde : source_color = vec4(0.015, 0.0, 0.03, 1.0);
// Qué tan adentro llega la oscuridad con la intensidad al máximo (0 = centro).
uniform float radio_minimo : hint_range(0.0, 1.0) = 0.3;
uniform float latidos_por_segundo = 1.1;
// Punto de la pantalla (0 a 1) alrededor del cual se cierra la oscuridad.
uniform vec2 centro = vec2(0.5);

// El latido son dos golpes seguidos: momento (0 a 1 dentro del latido) y anchura
// de cada uno, y qué tan fuerte es el segundo.
const float MOMENTO_GOLPE_1 = 0.1;
const float ANCHURA_GOLPE_1 = 0.07;
const float MOMENTO_GOLPE_2 = 0.32;
const float ANCHURA_GOLPE_2 = 0.09;
const float FUERZA_GOLPE_2 = 0.6;

// Raíz de 2 entre 2: la distancia del centro a una esquina, para que 1.0 sea la esquina.
const float DISTANCIA_A_LA_ESQUINA = 0.7071;
// La fuerza de la oscuridad es la intensidad por (BASE + latido + temblor).
const float FUERZA_BASE = 0.85;
const float FUERZA_POR_LATIDO = 0.2;
const float FUERZA_POR_TEMBLOR = 0.12;
const float VELOCIDAD_DEL_TEMBLOR = 3.1;
// Frecuencia del ruido de las lenguas y de los jirones.
const float ESCALA_LENGUAS = 2.6;
const float ESCALA_JIRONES = 5.5;
const float RADIO_INICIAL = 1.25;
// Cuánto entran las lenguas, y cuánto desplazan los jirones el borde.
const float PROFUNDIDAD_DE_LENGUAS = 0.5;
const float DESPLAZAMIENTO_DE_JIRONES = 0.3;
const float DIFUSION_DEL_BORDE = 0.38;
const float FUERZA_DE_MANCHAS = 0.7;

float azar(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float ruido(vec2 p) {
	vec2 celda = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = azar(celda);
	float b = azar(celda + vec2(1.0, 0.0));
	float c = azar(celda + vec2(0.0, 1.0));
	float d = azar(celda + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float ruido_fino(vec2 p) {
	float total = 0.0;
	float peso = 0.5;
	for (int i = 0; i < 4; i++) {
		total += ruido(p) * peso;
		p = p * 2.03 + vec2(17.0, 9.0);
		peso *= 0.5;
	}
	return total;
}

float fuerza_del_latido(float t) {
	float golpe_1 = exp(-pow((t - MOMENTO_GOLPE_1) / ANCHURA_GOLPE_1, 2.0));
	float golpe_2 = exp(-pow((t - MOMENTO_GOLPE_2) / ANCHURA_GOLPE_2, 2.0));
	return golpe_1 + FUERZA_GOLPE_2 * golpe_2;
}

void fragment() {
	vec2 centrado = UV - centro;
	float distancia = length(centrado) / DISTANCIA_A_LA_ESQUINA;
	float angulo = atan(centrado.y, centrado.x);

	float latido = fuerza_del_latido(fract(TIME * latidos_por_segundo));
	float temblor = ruido(vec2(TIME * VELOCIDAD_DEL_TEMBLOR, 4.0)) - 0.5;
	float variacion = FUERZA_BASE + FUERZA_POR_LATIDO * latido + FUERZA_POR_TEMBLOR * temblor;
	float fuerza = clamp(intensidad * variacion, 0.0, 1.0);

	// Lenguas de sombra: el borde entra más en unas direcciones que en otras, y
	// esas direcciones cambian con el tiempo.
	vec2 direccion = vec2(cos(angulo), sin(angulo));
	float lenguas = ruido_fino(direccion * ESCALA_LENGUAS + vec2(TIME * 0.22, -TIME * 0.17));
	float jirones = ruido_fino(UV * ESCALA_JIRONES + vec2(-TIME * 0.35, TIME * 0.28));

	float inicio = mix(RADIO_INICIAL, radio_minimo, fuerza);
	inicio -= (lenguas - 0.4) * PROFUNDIDAD_DE_LENGUAS * fuerza;
	float desplazada = distancia + (jirones - 0.5) * DESPLAZAMIENTO_DE_JIRONES;
	float sombra = smoothstep(inicio, inicio + DIFUSION_DEL_BORDE, desplazada);
	float cerca_del_borde = smoothstep(inicio - 0.25, inicio + 0.1, distancia);
	float manchas = smoothstep(0.62, 0.8, jirones) * cerca_del_borde;
	sombra = clamp(sombra + manchas * FUERZA_DE_MANCHAS, 0.0, 1.0);

	COLOR = vec4(color_borde.rgb, sombra * smoothstep(0.0, 0.25, fuerza));
}
