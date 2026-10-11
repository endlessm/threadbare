// SPDX-FileCopyrightText: The Threadbare Authors
// SPDX-License-Identifier: MPL-2.0
shader_type canvas_item;
// Una cuerda que cuelga desde muy arriba hasta un punto del suelo, vista por
// una cámara que mira hacia abajo. Se calcula en perspectiva de verdad: lo que
// está más alto queda más cerca de la cámara, así que se ve más grande y se
// aleja del centro de la pantalla. Por eso la cuerda se inclina y crece cuando
// la cámara se mueve, como un objeto en primer plano.
// La parte cercana se vuelve transparente por tramado (se le quitan píxeles en
// un patrón), y también lo que tapa el centro, donde está Lino.
// Se usa sobre un ColorRect a pantalla completa.

// Dónde toca el suelo, en píxeles de pantalla, y el tamaño de la pantalla.
uniform vec2 ancla = vec2(640.0, 360.0);
uniform vec2 pantalla = vec2(1280.0, 720.0);
// El punto de la pantalla que queda justo debajo de la cámara (su centro,
// salvo durante la bajada, en que la cámara va pegada a la cuerda).
uniform vec2 bajo_la_camara = vec2(640.0, 360.0);
// Zoom de la cámara (píxeles de pantalla por píxel del mundo).
uniform float zoom = 1.0;
// Hasta qué altura se ve la cuerda, como parte de la altura de la cámara
// (cuanto más cerca de 1, más enorme llega a verse antes de salir de cuadro).
uniform float altura_maxima : hint_range(0.1, 0.97) = 0.93;
// La cuerda no cuelga del todo recta: arriba está corrida hacia el norte
// (en píxeles del mundo). Así nunca apunta justo a la cámara.
uniform float inclinacion = 45.0;
// Medio ancho de la cuerda en el suelo, en píxeles del mundo.
uniform float grosor = 6.0;
// Hace correr las hebras (para la bajada).
uniform float corrimiento = 0.0;
// 0 = se ve; 1 = se deshizo del todo (por tramado).
uniform float desvanecer : hint_range(0.0, 1.0) = 0.0;
// Tamaño del píxel de la cuerda lejos de la cámara, en píxeles de pantalla.
uniform float pixel = 4.0;
// Lo que tapa a Lino (el centro de la pantalla) se ve más calado.
uniform float radio_despejado = 170.0;
uniform vec4 color_claro : source_color = vec4(0.62, 0.59, 0.54, 1.0);
uniform vec4 color_base : source_color = vec4(0.44, 0.41, 0.38, 1.0);
uniform vec4 color_sombra : source_color = vec4(0.27, 0.25, 0.24, 1.0);
uniform vec4 color_contorno : source_color = vec4(0.1, 0.09, 0.1, 1.0);

const int TRAMOS = 28;
const float VUELTAS_DE_HEBRA = 26.0;
// La cuerda se mece: velocidad, desfase por altura y amplitud (píxeles del mundo).
const float MECIDO_VELOCIDAD = 1.1;
const float MECIDO_DESFASE = 4.0;
const float MECIDO_AMPLITUD = 5.0;
// Hebras: cuánto se tuercen con el costado, y dónde empieza la sombra (en la hebra y
// a lo ancho, de -1 a 1) y el contorno.
const float TORSION_DE_HEBRA = 0.55;
const float INICIO_SOMBRA_DE_HEBRA = 0.82;
const float INICIO_SOMBRA_DE_LADO = 0.35;
const float FUERZA_SOMBRA_DE_LADO = 0.6;
const float INICIO_CONTORNO = 0.78;
// Tramado: el píxel crece un paso cada TRAMO_DE_CERCANIA de aumento, hasta 2 pasos.
const float TRAMO_DE_CERCANIA = 4.0;
const float MAX_PASOS_DE_GRANO = 2.0;
// Opacidad: lo cercano (aumento de 1.6 a 7) baja hasta OPACIDAD_MUY_CERCA, lo que tapa
// el centro hasta OPACIDAD_EN_EL_CENTRO, y el pedazo junto al suelo (aumento de 1.05
// a 1.5) siempre se ve entero.
const float OPACIDAD_MUY_CERCA = 0.32;
const float OPACIDAD_EN_EL_CENTRO = 0.45;
const float CERCA_DESDE = 1.6;
const float CERCA_HASTA = 7.0;
const float SUELO_DESDE = 1.05;
const float SUELO_HASTA = 1.5;
const float PUNTA_DESDE = 0.9;

// Matriz de umbrales de 4x4 para el tramado.
const float MATRIZ_TRAMADO[16] = float[16](
	0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0
);

float tramado(vec2 celda) {
	int x = int(mod(celda.x, 4.0));
	int y = int(mod(celda.y, 4.0));
	return (MATRIZ_TRAMADO[y * 4 + x] + 0.5) / 16.0;
}

// Cuánto agranda la perspectiva a la altura u (0 = suelo, 1 = lo más alto).
float aumento(float u) {
	return 1.0 / (1.0 - altura_maxima * u);
}

// Dónde cae en la pantalla el punto de la cuerda que está a la altura u.
vec2 en_pantalla(float u) {
	vec2 centro = bajo_la_camara;
	float mecido = sin(TIME * MECIDO_VELOCIDAD + u * MECIDO_DESFASE) * MECIDO_AMPLITUD * u;
	vec2 suelo = ancla + vec2(mecido, -inclinacion * u) * zoom;
	return centro + (suelo - centro) * aumento(u);
}

void fragment() {
	vec2 punto = UV * pantalla;
	// Se busca qué tramo de la cuerda pasa por este píxel. Si pasan varios,
	// gana el más alto, que es el que está más cerca de la cámara.
	float altura = -1.0;
	float lado = 0.0;
	vec2 desde = en_pantalla(0.0);
	float u_desde = 0.0;
	for (int i = 1; i <= TRAMOS; i++) {
		// Más tramos arriba, donde la cuerda crece más rápido.
		float t = float(i) / float(TRAMOS);
		float u_hasta = 1.0 - (1.0 - t) * (1.0 - t);
		vec2 hasta = en_pantalla(u_hasta);
		vec2 tramo = hasta - desde;
		float largo2 = max(dot(tramo, tramo), 0.0001);
		float f = clamp(dot(punto - desde, tramo) / largo2, 0.0, 1.0);
		float u = mix(u_desde, u_hasta, f);
		float ancho = grosor * zoom * aumento(u);
		vec2 separacion = punto - (desde + tramo * f);
		float distancia = length(separacion);
		if (distancia <= ancho) {
			altura = u;
			vec2 normal = normalize(vec2(-tramo.y, tramo.x) + vec2(0.0001));
			lado = dot(separacion, normal) / ancho;
		}
		desde = hasta;
		u_desde = u_hasta;
	}
	if (altura < 0.0) {
		COLOR = vec4(0.0);
	} else {
		float cerca = aumento(altura);
		// Las hebras trenzadas: franjas en diagonal a lo largo de la cuerda.
		float hebra = fract(altura * VUELTAS_DE_HEBRA - corrimiento + lado * TORSION_DE_HEBRA);
		vec3 color = mix(color_base.rgb, color_claro.rgb, step(0.5, hebra));
		float sombra_de_hebra = step(INICIO_SOMBRA_DE_HEBRA, hebra);
		float sombra_de_lado = step(INICIO_SOMBRA_DE_LADO, lado) * FUERZA_SOMBRA_DE_LADO;
		color = mix(color, color_sombra.rgb, clamp(sombra_de_hebra + sombra_de_lado, 0.0, 1.0));
		color = mix(color, color_contorno.rgb, step(INICIO_CONTORNO, abs(lado)));

		// Tramado, con píxeles más grandes cuanto más cerca de la cámara.
		float pasos = floor(clamp((cerca - 1.0) / TRAMO_DE_CERCANIA, 0.0, MAX_PASOS_DE_GRANO));
		float grano = pixel * (1.0 + pasos);
		vec2 celda = floor(punto / grano);
		float opacidad = mix(1.0, OPACIDAD_MUY_CERCA, smoothstep(CERCA_DESDE, CERCA_HASTA, cerca));
		float del_centro = distance(punto, pantalla * 0.5);
		float centro_tapado = smoothstep(radio_despejado * 0.4, radio_despejado, del_centro);
		opacidad *= mix(OPACIDAD_EN_EL_CENTRO, 1.0, centro_tapado);
		// El pedazo junto al suelo siempre se ve entero.
		opacidad = mix(1.0, opacidad, smoothstep(SUELO_DESDE, SUELO_HASTA, cerca));
		opacidad *= 1.0 - desvanecer;
		// Y arriba del todo se pierde, en vez de cortarse de golpe.
		opacidad *= 1.0 - smoothstep(PUNTA_DESDE, 1.0, altura);
		COLOR = vec4(color, step(tramado(celda), opacidad));
	}
}
