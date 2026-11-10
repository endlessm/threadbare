// SPDX-FileCopyrightText: The Threadbare Authors
// SPDX-License-Identifier: MPL-2.0
shader_type canvas_item;
// La tela del final: urdimbre y trama de hilos oscuros, en píxeles grandes.

uniform vec2 pantalla = vec2(1280.0, 720.0);
// Lado, en píxeles, de cada cruce de hilos.
uniform float hebra = 6.0;
uniform vec4 color_urdimbre : source_color = vec4(0.17, 0.12, 0.11, 1.0);
uniform vec4 color_trama : source_color = vec4(0.13, 0.10, 0.10, 1.0);

const float TAMANO_DEL_PIXEL = 2.0;
const float MEDIA_VUELTA = 3.1416;
// Cada hilo es más claro en el medio de su cruce (curva) y varía un poco al azar.
const float BRILLO_BASE = 0.7;
const float BRILLO_DE_LA_CURVA = 0.3;
const float VARIACION_AL_AZAR = 0.08;

float azar(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	// Píxeles de 2x2, para que se vea como el resto del juego.
	vec2 px = floor(UV * pantalla / TAMANO_DEL_PIXEL) * TAMANO_DEL_PIXEL;
	vec2 celda = floor(px / hebra);
	vec2 dentro = fract(px / hebra);
	// En cada cruce queda arriba un hilo distinto: urdimbre o trama.
	bool urdimbre = mod(celda.x + celda.y, 2.0) < 1.0;
	float curva = urdimbre ? sin(dentro.y * MEDIA_VUELTA) : sin(dentro.x * MEDIA_VUELTA);
	vec3 base = urdimbre ? color_urdimbre.rgb : color_trama.rgb;
	base *= BRILLO_BASE + BRILLO_DE_LA_CURVA * curva + (azar(celda) - 0.5) * VARIACION_AL_AZAR;
	COLOR = vec4(base, 1.0);
}
