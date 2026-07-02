 shader_type canvas_item;

uniform vec4 color_actual : source_color = vec4(0.5, 0.0, 0.5, 1.0); 
uniform vec4 color_fondo_gris : source_color = vec4(0.2, 0.2, 0.2, 0.8);

uniform vec2 posicion_jugador = vec2(0.5, 0.5); 

uniform float radio_circulo : hint_range(0.0, 1.5) = 0.0;

uniform bool invertir_mascara = false;

uniform vec2 tamano_mapa = vec2(1000.0, 1000.0);

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    vec2 proporcion = vec2(tamano_mapa.x / tamano_mapa.y, 1.0);
    
    vec2 uv_corregida = UV * proporcion;
    vec2 posicion_corregida = posicion_jugador * proporcion;

    float distancia = distance(uv_corregida, posicion_corregida);
    
    float mascara = step(radio_circulo, distancia);
    
    vec3 color_pantalla = texture(screen_texture, SCREEN_UV).rgb;
    vec4 color_invertido = vec4(vec3(1.0) - color_pantalla, 1.0);

    if (!invertir_mascara) {

        
        vec4 color_burbuja = mix(color_invertido, color_actual, 0.3); // 0.4 mezcla un poco de tu morado con la inversión
        color_burbuja.a = color_actual.a * (1.0 - mascara);
        COLOR = color_burbuja;
        
    } else {
        float mascara_amarilla = 1.0 - mascara;
        
        vec4 color_burbuja_amarilla = mix(color_invertido, color_actual, 0.3); 
        color_burbuja_amarilla.a *= mascara_amarilla;
         
        vec4 color_fondo = color_fondo_gris; 
        color_fondo.a *= mascara;
        
        COLOR = mix(color_fondo, color_burbuja_amarilla, color_burbuja_amarilla.a);
    }
}
