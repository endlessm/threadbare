shader_type canvas_item;

// Control de filtro de color
uniform vec4 filter_color : source_color = vec4(0.13, 0.47, 0.77, 1.0); // #2277c4 por defecto
uniform float filter_intensity : hint_range(0.0, 1.0) = 1.0;

// Controles de oscuridad
uniform bool enable_darkness = true;
uniform float darkness : hint_range(0.0, 1.0) = 0.5;
uniform float vignette_strength : hint_range(0.0, 10.0) = 1.2;
uniform float vignette_size : hint_range(0.1, 1.0) = 0.5;

// Controles de ruido y grano
uniform bool enable_noise = true;
uniform float noise_intensity : hint_range(0.0, 0.5) = 0.12;
uniform float grain_amount : hint_range(0.0, 1.0) = 0.25;

uniform sampler2D screen_texture : hint_screen_texture;

float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    f = f * f * (3.0 - 2.0 * f);
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
    vec2 uv = SCREEN_UV;
    vec4 color = texture(screen_texture, uv);
    
    // Aplicar filtro de color
    color.rgb = mix(color.rgb, color.rgb * filter_color.rgb, filter_intensity);
    
    // Viñeta
    vec2 center = vec2(0.5, 0.5);
    float dist = length(uv - center);
    float vignette = smoothstep(vignette_size, vignette_size + 0.35, dist);
    vignette = pow(vignette, max(0.0001, vignette_strength));
    
    // Oscurecimiento base + viñeta
    if (enable_darkness) {
        float total_darkness = darkness + (vignette * (1.0 - darkness));
        color.rgb *= (1.0 - total_darkness);
    } else {
        color.rgb *= mix(1.0, 0.7, vignette);
    }
    
    // Suciedad y grano
    if (enable_noise) { 
        float dirt = noise(uv * 50.0 + TIME * 0.1);
        dirt = mix(dirt, noise(uv * 100.0), 0.5);
        color.rgb -= dirt * noise_intensity;
        float grain = random(uv * 1000.0 + fract(TIME));
        color.rgb += (grain - 0.5) * (grain_amount * 0.1);
    }
    
    COLOR = color;
}