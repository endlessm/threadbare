// SPDX-FileCopyrightText: The Threadbare Authors
// SPDX-License-Identifier: MPL-2.0
shader_type canvas_item;

// 1 = con todo su color; 0 = gris.
uniform float saturation : hint_range(0.0, 1.0) = 0.0;
// Brillo del mundo: 0.6 reduce el brillo un 40 %.
uniform float darkness_factor : hint_range(0.0, 1.0) = 0.6;

// Ondas de color: anillos que salen de un punto del mundo y, al pasar,
// devuelven la saturación poco a poco. Con onda_tiempo < 0 están apagadas.
uniform vec2 onda_origen = vec2(0.0);
uniform float onda_tiempo = -1.0;
uniform float onda_velocidad = 330.0;
uniform float onda_intervalo = 4.5;
uniform int onda_cantidad = 5;
uniform float onda_ancho = 260.0;
uniform float onda_brillo_cresta = 0.25;
// Onda pequeña al recoger un hilo: el color solo aparece en el anillo mientras
// pasa (no se queda), y el anillo se apaga al llegar a onda_alcance píxeles.
uniform bool onda_solo_cresta = false;
uniform float onda_alcance = 0.0;
// Cuánto color trae el anillo de la onda pequeña (0 = nada, 1 = color pleno).
uniform float onda_color_cresta = 1.0;
// El anillo puede teñirse del color del hilo que lo lanza.
uniform vec3 onda_tinte : source_color = vec3(1.0);
uniform float onda_tinte_fuerza : hint_range(0.0, 1.0) = 0.0;
// Permite hacer aparecer poco a poco algo que usa este material.
uniform float opacidad : hint_range(0.0, 1.0) = 1.0;

const int MAXIMO_DE_ONDAS = 8;
const vec3 LUMINANCIA = vec3(0.299, 0.587, 0.114);
// La onda pequeña empieza a apagarse al llegar a esta fracción de onda_alcance.
const float INICIO_DEL_APAGADO = 0.55;
// Brillo del tinte: gris * GANANCIA_DEL_TINTE + BASE_DEL_TINTE.
const float GANANCIA_DEL_TINTE = 1.5;
const float BASE_DEL_TINTE = 0.2;

varying vec2 pos_mundo;
// Transparencia que el nodo pide con modulate / self_modulate (por ejemplo, el
// parpadeo de fantasma de Luto). El color del modulate se sigue ignorando.
varying float opacidad_del_nodo;

void vertex() {
	pos_mundo = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	opacidad_del_nodo = COLOR.a;
}

void fragment() {
	vec4 color_textura = texture(TEXTURE, UV);

	float saturacion_final = saturation;
	float cresta = 0.0;
	if (onda_tiempo >= 0.0) {
		float distancia = distance(pos_mundo, onda_origen);
		float medio_ancho = onda_ancho * 0.5;
		float ondas_pasadas = 0.0;
		for (int i = 0; i < MAXIMO_DE_ONDAS; i++) {
			if (i >= onda_cantidad) {
				break;
			}
			float radio = (onda_tiempo - float(i) * onda_intervalo) * onda_velocidad;
			if (radio > 0.0) {
				ondas_pasadas += 1.0 - smoothstep(radio - onda_ancho, radio, distancia);
				float cerca_del_anillo = abs(distancia - radio + medio_ancho) / medio_ancho;
				cresta = max(cresta, 1.0 - clamp(cerca_del_anillo, 0.0, 1.0));
			}
		}
		if (onda_solo_cresta) {
			if (onda_alcance > 0.0) {
				cresta *= 1.0 - smoothstep(onda_alcance * INICIO_DEL_APAGADO, onda_alcance, distancia);
			}
			saturacion_final = mix(saturation, 1.0, cresta * onda_color_cresta);
		} else {
			float avance = clamp(ondas_pasadas / float(onda_cantidad), 0.0, 1.0);
			saturacion_final = mix(saturation, 1.0, avance);
		}
	}

	float gris = dot(color_textura.rgb, LUMINANCIA);
	vec3 color = mix(vec3(gris), color_textura.rgb, saturacion_final);

	// El anillo de un hilo se tiñe de su color, conservando la luz de cada cosa.
	vec3 tinte = onda_tinte * (gris * GANANCIA_DEL_TINTE + BASE_DEL_TINTE);
	color = mix(color, tinte, cresta * onda_tinte_fuerza);

	COLOR.rgb = color * darkness_factor * (1.0 + onda_brillo_cresta * cresta);
	COLOR.a = color_textura.a * opacidad * opacidad_del_nodo;
}
