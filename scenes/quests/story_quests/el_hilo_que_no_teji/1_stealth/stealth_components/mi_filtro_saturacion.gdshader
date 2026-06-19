	shader_type canvas_item;

	// ESTA es la variable que tu script lee y modifica. 
	// 0.0 es totalmente blanco y negro, 1.0 es color normal.
	uniform float saturation : hint_range(0.0, 1.0) = 0.0;

	// Requerido para capturar lo que hay detrás del ColorRect
	uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

	void fragment() {
	    // Tomar el color real del juego detrás del CanvasLayer
	    vec4 current_color = texture(screen_texture, SCREEN_UV);
	    
	    // Calcular el nivel de gris (usando la fórmula de luminiscencia estándar)
	    float gray = dot(current_color.rgb, vec3(0.299, 0.587, 0.114));
	    vec3 grayscale = vec3(gray);
	    
	    // Mezclar el color en blanco y negro con el color original usando el estado de saturación global
	    COLOR.rgb = mix(grayscale, current_color.rgb, saturation);
	    COLOR.a = current_color.a;
	}