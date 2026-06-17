 shader_type canvas_item;

// Colores que controlaremos desde la animación
uniform vec4 color_actual : source_color = vec4(0.5, 0.0, 0.5, 1.0); 
uniform vec4 color_fondo_gris : source_color = vec4(0.2, 0.2, 0.2, 0.8);

// Posición que le mandará el script (de 0.0 a 1.0)
uniform vec2 posicion_jugador = vec2(0.5, 0.5); 
// El radio de la pantalla (de 0.0 a 1.5)
uniform float radio_circulo : hint_range(0.0, 1.5) = 0.0;

// Interruptor para cambiar de expansión a contracción
uniform bool invertir_mascara = false;

// 🌍 El script te pasa automáticamente el tamaño de tu ColorRect gigante
uniform vec2 tamano_mapa = vec2(1000.0, 1000.0);

// 🔍 NUEVO: Captura de forma automática todo lo que pasa por debajo del ColorRect
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    // 🧮 CORRECCIÓN MATEMÁTICA: 
    // Calculamos la proporción de tu rectángulo para evitar estiramientos
    vec2 proporcion = vec2(tamano_mapa.x / tamano_mapa.y, 1.0);
    
    // Multiplicamos tanto los píxeles (UV) como la posición por esa proporción
    vec2 uv_corregida = UV * proporcion;
    vec2 posicion_corregida = posicion_jugador * proporcion;

    // 🎯 Calculamos la distancia real sin deformaciones
    float distancia = distance(uv_corregida, posicion_corregida);
    
    // ✂️ CORTE SÓLIDO: 1.0 fuera del círculo, 0.0 dentro del círculo
    float mascara = step(radio_circulo, distancia);
    
    // 🎨 OBTENER COLOR DE FONDO DETRÁS DEL RECTÁNGULO
    vec3 color_pantalla = texture(screen_texture, SCREEN_UV).rgb;
    // Creamos la versión con los colores invertidos (filtro negativo)
    vec4 color_invertido = vec4(vec3(1.0) - color_pantalla, 1.0);

    if (!invertir_mascara) {
        // --- MODO EXPANSIÓN (El círculo nace y crece) ---
        // Lo que está DENTRO del círculo (mascara == 0.0) invierte el fondo y se mezcla con tu color morado
        // Lo que está FUERA del círculo (mascara == 1.0) se vuelve transparente (0.0)
        
        vec4 color_burbuja = mix(color_invertido, color_actual, 0.3); // 0.4 mezcla un poco de tu morado con la inversión
        color_burbuja.a = color_actual.a * (1.0 - mascara);
        COLOR = color_burbuja;
        
    } else {
        // --- MODO CONTRACCIÓN ---
        float mascara_amarilla = 1.0 - mascara;
        
        // Dentro de la burbuja (invertido + tu color)
        vec4 color_burbuja_amarilla = mix(color_invertido, color_actual, 0.3); 
        color_burbuja_amarilla.a *= mascara_amarilla;
         
        // Fuera de la burbuja (pantalla grisácea de fondo)
        vec4 color_fondo = color_fondo_gris; 
        color_fondo.a *= mascara;
        
        COLOR = mix(color_fondo, color_burbuja_amarilla, color_burbuja_amarilla.a);
    }
}
