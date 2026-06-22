shader_type canvas_item;

// Parámetros ajustables en el Inspector
uniform vec4 fog_color : source_color = vec4(0.45, 0.48, 0.52, 0.4);
uniform float speed : hint_range(0.0, 1.0) = 0.03;
uniform float detail_steps : hint_range(1.0, 6.0) = 4.0;
uniform float thread_shredding : hint_range(0.1, 2.0) = 1.4; // Subido para rasgar más el fondo por defecto
uniform float density : hint_range(0.1, 5.0) = 1.0; 

// Variable puente para transferir la posición del mapa real al fragmento
varying vec2 world_position;

float rand(vec2 coord) {
	return fract(sin(dot(coord, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(vec2 coord) {
	vec2 i = floor(coord);
	vec2 f = fract(coord);
	float a = rand(i);
	float b = rand(i + vec2(1.0, 0.0));
	float c = rand(i + vec2(0.0, 1.0));
	float d = rand(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// Movimiento fractal para deshilachar la niebla
float fbm(vec2 coord) {
	float value = 0.0;
	float scale = 1.0;

	// Rotación para simular viento cruzado irregular
	mat2 magic_rotation = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));

	for (int i = 0; i < 4; i++) {
		value += noise(coord) * scale;
		coord = magic_rotation * coord * 2.5;
		scale *= 0.45;
	}
	return value;
}

void vertex() {
	// MODEL_MATRIX calcula la posición respecto al origen del mapa.
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	// Escalamos la posición base de forma fija para el tamaño de las nubes
	vec2 base_uv = world_position * 0.0015;
	
	// Corrientes de aire cruzadas
	vec2 wind_1 = vec2(TIME * speed, TIME * speed * 0.15);
	vec2 wind_2 = vec2(-TIME * speed * 0.4, TIME * speed * 0.3);
	
	float layer1 = fbm(base_uv + wind_1);
	float layer2 = fbm((base_uv * 1.5) + wind_2);
	
	// MEZCLA SUAVE: En lugar de multiplicar, promediamos las capas para un resultado más orgánico
	float mixed_noise = mix(layer1, layer2, 0.5);
	
	// FILTRO DE CONTRASTE AGRESIVO:
	// Subimos el umbral inferior (0.55) para asegurarnos de que las zonas bajas se vuelvan COMPLETAMENTE transparentes.
	// La densidad ahora actúa reduciendo la opacidad máxima de forma directa y correcta.
	float final_shredded_fog = smoothstep(0.55, 0.85, mixed_noise);
	
	// Aplicamos el modificador exponencial para rasgar los bordes
	final_shredded_fog = pow(final_shredded_fog, thread_shredding);
	
	// El parámetro 'density' ahora controla directamente el tope máximo de visibilidad (0.1 a 1.0 sugerido)
	float alpha_mask = final_shredded_fog * fog_color.a * density;
	
	COLOR = vec4(fog_color.rgb, alpha_mask);
}
