// SPDX-FileCopyrightText: The Threadbare Authors
// SPDX-License-Identifier: MPL-2.0
shader_type canvas_item;
// El haz: luz que atraviesa la niebla y cae sobre Lino.

// 0 = apagado; 1 = encendido del todo.
uniform float brillo : hint_range(0.0, 1.0) = 0.0;
// Dónde cae (0-1) y qué tan ancho es arriba y abajo (en ancho de pantalla).
uniform vec2 pie = vec2(0.5, 0.8);
uniform float ancho_arriba = 0.03;
uniform float ancho_abajo = 0.1;
uniform vec4 color_luz : source_color = vec4(1.0, 0.97, 0.9, 1.0);

// Opacidad del haz arriba y abajo, y la del charco de luz en el suelo.
const float OPACIDAD_ARRIBA = 0.3;
const float OPACIDAD_ABAJO = 0.6;
const float OPACIDAD_DEL_CHARCO = 0.75;
// Opacidad máxima con el haz encendido del todo.
const float OPACIDAD_MAXIMA = 0.6;
// Desde qué fracción del ancho del haz empieza a desvanecerse hacia los lados.
const float BORDE_SUAVE_DEL_HAZ = 0.15;
// El haz se corta un poco por encima y por debajo de donde cae (en alto de pantalla).
const float MARGEN_SOBRE_EL_PIE = 0.03;
const float MARGEN_BAJO_EL_PIE = 0.02;
// El charco es una elipse: ancho (en anchos del haz abajo) y alto (en alto de pantalla).
const float ANCHO_DEL_CHARCO = 1.25;
const float ALTO_DEL_CHARCO = 0.04;
const float BORDE_SUAVE_DEL_CHARCO = 0.3;

void fragment() {
	float bajada = clamp(UV.y / pie.y, 0.0, 1.0);
	float ancho = mix(ancho_arriba, ancho_abajo, bajada);
	float haz = smoothstep(1.0, BORDE_SUAVE_DEL_HAZ, abs(UV.x - pie.x) / ancho);
	float corte = smoothstep(pie.y + MARGEN_SOBRE_EL_PIE, pie.y - MARGEN_BAJO_EL_PIE, UV.y);
	haz *= corte * mix(OPACIDAD_ARRIBA, OPACIDAD_ABAJO, bajada);
	vec2 charco = (UV - pie) / vec2(ancho_abajo * ANCHO_DEL_CHARCO, ALTO_DEL_CHARCO);
	float suelo = smoothstep(1.0, BORDE_SUAVE_DEL_CHARCO, length(charco)) * OPACIDAD_DEL_CHARCO;
	COLOR = vec4(color_luz.rgb, max(haz, suelo) * brillo * OPACIDAD_MAXIMA);
}
