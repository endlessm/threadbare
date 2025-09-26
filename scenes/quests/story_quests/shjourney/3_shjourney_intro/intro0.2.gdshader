shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	  float y_limit = 0.4; // valores entre 0.0 (abajo) y 1.0 (arriba)

    // Si está por encima del límite, aplicar movimiento
    if (UV.y < y_limit) {
        // Suavidad del viento
        float strength = (1.0 - UV.y / y_limit); // más fuerte arriba, más suave abajo
        vec2 offset = vec2(sin(UV.y * 15.0 + TIME * 2.0) * 0.01 * strength, 0.0);
        COLOR = texture(TEXTURE, UV + offset);
    } else {
        // Parte inferior sin mover
        COLOR = texture(TEXTURE, UV);
    }
}