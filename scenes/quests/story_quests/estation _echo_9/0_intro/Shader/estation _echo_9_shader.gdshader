shader_type canvas_item;
render_mode unshaded, skip_vertex_transform;

const float curvature = 7.0;
const float vignette_multiplier = 1.0;

uniform sampler2D screen_texture: hint_screen_texture, filter_linear_mipmap;

// Función de ruido simple para el jitter
float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898,78.233))) * 43758.5453);
}

void fragment() {
    // Movimiento sutil tipo VHS - wobble y jitter
    float time_factor = TIME * 0.5;
    vec2 wobble_uv = SCREEN_UV;
    
    // Efecto de wobble (oscilación suave)
    wobble_uv.x += sin(wobble_uv.y * 20.0 + time_factor) * 0.001;
    wobble_uv.y += cos(wobble_uv.x * 15.0 + time_factor * 1.2) * 0.0008;
    
    // Jitter aleatorio sutil
    wobble_uv.x += (rand(vec2(time_factor, wobble_uv.y)) - 0.5) * 0.002;
    wobble_uv.y += (rand(vec2(wobble_uv.x, time_factor * 1.5)) - 0.5) * 0.001;
    
    // Distorsión de curvatura
    vec2 centered_uv = wobble_uv * 2.0 - 1.0;
    vec2 uv_offset = centered_uv.yx / curvature;
    vec2 warped_uv = centered_uv + centered_uv * uv_offset * uv_offset;
    
    // Efectos visuales VHS
    vec3 cutoff = vec3(step(abs(warped_uv.x), 1.0) * step(abs(warped_uv.y), 1.0));
    
    // Scanlines dinámicos
    float scanline_speed = 1.0;
    vec3 scanlines = vec3(sin((warped_uv.y + time_factor * 0.1) * 180.0) * 0.1 + 0.9);
    
    // Vignette
    vec3 vignette = vec3(length(pow(abs(centered_uv), vec2(4.0)) / 3.0));
    
    // Color final con todos los efectos
    vec3 screen_color = textureLod(screen_texture, (warped_uv + 1.0) / 2.0, 0.2).rgb * cutoff * scanlines;
    screen_color -= vignette * vignette_multiplier;
    
    COLOR = vec4(screen_color, 1.0);
}