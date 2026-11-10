// SPDX-FileCopyrightText: The Threadbare Authors
// SPDX-License-Identifier: MPL-2.0
shader_type canvas_item;
// Elián como sombra dentro de la niebla: una silueta que se pierde hacia
// abajo, con los ojos encendidos. "detalle" deja entrever su figura.

const vec3 LUMINANCIA = vec3(0.299, 0.587, 0.114);
const vec3 COLOR_DE_LOS_OJOS = vec3(0.93, 0.95, 1.0);
// Los ojos son lo más claro del dibujo: entre estas dos luces pasan de apagados a encendidos.
const float OJO_DESDE = 0.72;
const float OJO_HASTA = 0.85;
// Cuánto del dibujo real se mezcla con el color de sombra cuando detalle = 1.
const float MEZCLA_DEL_DETALLE = 0.55;
// La silueta se ve entera hasta CUERPO_ENTERO_HASTA y se pierde del todo en
// CUERPO_PERDIDO_EN (alturas de la figura, de 0 arriba a 1 abajo).
const float CUERPO_ENTERO_HASTA = 0.42;
const float CUERPO_PERDIDO_EN = 0.9;
// La mano: zona del dibujo (en píxeles) donde se deja ver. Se deshace hacia el brazo
// (x) y hacia abajo (y), donde están los libros, y se corta justo sobre los dedos.
const vec2 MANO_EN_X = vec2(38.0, 78.0);
const vec2 MANO_EN_Y = vec2(70.0, 44.0);
const vec2 MANO_CORTE_ARRIBA = vec2(-34.0, -28.0);

// Qué tanto se ve la silueta (0 = nada, 1 = entera), sus ojos y su figura.
uniform float sombra : hint_range(0.0, 1.0) = 0.0;
uniform float ojos : hint_range(0.0, 1.0) = 0.0;
uniform float detalle : hint_range(0.0, 1.0) = 0.0;
// Cuánto se ve la mano que sale de la niebla, aunque el resto siga oculto.
uniform float mano : hint_range(0.0, 1.0) = 0.0;
uniform vec4 color_sombra : source_color = vec4(0.2, 0.21, 0.27, 1.0);
// Alto de la figura entera y dónde está este dibujo dentro de ella.
uniform float alto = 256.0;
uniform float desplazamiento = 0.0;
// El cuerpo deja libre el sitio de la cabeza, que se dibuja aparte (riendo).
uniform bool recortar_cabeza = false;
uniform sampler2D cabeza : filter_nearest;
uniform vec4 region_cabeza = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec2 esquina_cabeza = vec2(0.0);
uniform vec2 medida_cabeza = vec2(61.0, 80.0);

varying vec2 lugar;

void vertex() {
	lugar = VERTEX;
}

void fragment() {
	vec4 figura = texture(TEXTURE, UV);
	float presencia = figura.a;
	if (recortar_cabeza) {
		vec2 en_cabeza = (lugar - esquina_cabeza) / medida_cabeza;
		if (en_cabeza.x >= 0.0 && en_cabeza.x <= 1.0 && en_cabeza.y >= 0.0 && en_cabeza.y <= 1.0) {
			presencia *= 1.0 - texture(cabeza, region_cabeza.xy + en_cabeza * region_cabeza.zw).a;
		}
	}
	float luz = dot(figura.rgb, LUMINANCIA);
	float ojo = smoothstep(OJO_DESDE, OJO_HASTA, luz) * presencia;
	float altura = (lugar.y + desplazamiento) / alto + 0.5;
	float cuerpo = smoothstep(CUERPO_PERDIDO_EN, CUERPO_ENTERO_HASTA, altura);
	vec3 con_detalle = mix(color_sombra.rgb, figura.rgb, MEZCLA_DEL_DETALLE);
	vec3 color = mix(color_sombra.rgb, con_detalle, detalle);
	color = mix(color, COLOR_DE_LOS_OJOS, ojo * ojos);
	float zona_mano = smoothstep(MANO_EN_X.x, MANO_EN_X.y, lugar.x);
	zona_mano *= smoothstep(MANO_EN_Y.x, MANO_EN_Y.y, lugar.y);
	zona_mano *= smoothstep(MANO_CORTE_ARRIBA.x, MANO_CORTE_ARRIBA.y, lugar.y);
	float visible = max(sombra * cuerpo, mano * zona_mano);
	COLOR = vec4(color, presencia * max(visible, ojo * ojos));
}
