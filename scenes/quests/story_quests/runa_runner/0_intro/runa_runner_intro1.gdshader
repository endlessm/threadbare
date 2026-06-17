shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(UV, center);
    float radius = progress;
    if (dist < radius) {
        discard;
    }
    COLOR = vec4(0.0, 0.0, 0.0, 1.0);
}