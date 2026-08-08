shader_type canvas_item;
uniform float nivel_gris : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec4 color_original = texture(TEXTURE, UV);
    // Fórmula estándar para convertir RGB a escala de grises
    float gris_puro = dot(color_original.rgb, vec3(0.299, 0.587, 0.114));
    COLOR.rgb = mix(color_original.rgb, vec3(gris_puro), nivel_gris);
    COLOR.a = color_original.a;
}