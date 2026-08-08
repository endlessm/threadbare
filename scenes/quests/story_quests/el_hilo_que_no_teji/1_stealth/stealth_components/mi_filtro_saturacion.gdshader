shader_type canvas_item;

uniform float saturation : hint_range(0.0, 1.0) = 0.0;
// Factor para restar luminosidad (0.6 reduce el brillo un 40%)
uniform float darkness_factor : hint_range(0.0, 1.0) = 0.6; 

void fragment() {
    // Tomar el color de la textura del objeto o pantalla
    vec4 tex_color = texture(TEXTURE, UV);
    
    // Calcular el nivel de gris base
    float gray = dot(tex_color.rgb, vec3(0.299, 0.587, 0.114));
    
    // Mezclar el gris con el color original según la saturación
    vec3 mixed_color = mix(vec3(gray), tex_color.rgb, saturation);
    
    // Multiplicamos por el factor para oscurecer y quitar el efecto "lavado"
    COLOR.rgb = mixed_color * darkness_factor;
    COLOR.a = tex_color.a; // Mantener las transparencias perfectas
}
