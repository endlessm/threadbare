shader_type canvas_item;

uniform vec2 light_pos = vec2(0.5, 0.5);
uniform float light_radius : hint_range(0.0, 1.0) = 0.5;
uniform float cone_angle : hint_range(0.0, 6.28318) = 0.5;
uniform float cone_direction : hint_range(-3.14159, 3.14159) = 0.0;
uniform float darkness : hint_range(0.0, 1.0) = 0.96;
uniform float edge_softness : hint_range(0.0, 0.3) = 0.08;
uniform float aspect_ratio : hint_range(0.5, 3.0) = 1.7778;

void fragment() {
    vec2 uv = UV;
    vec2 corrected_uv = vec2((uv.x - light_pos.x) * aspect_ratio, uv.y - light_pos.y);
    float dist = length(corrected_uv);
    float frag_angle = atan(corrected_uv.y, corrected_uv.x);
    float angle_diff = frag_angle - cone_direction;
    angle_diff = mod(angle_diff + 3.14159, 6.28318) - 3.14159;
    angle_diff = abs(angle_diff);
    float half_cone = cone_angle * 0.5;
    float in_cone = 1.0 - smoothstep(half_cone - edge_softness, half_cone + edge_softness, angle_diff);
    float in_radius = 1.0 - smoothstep(light_radius - edge_softness, light_radius, dist);
    float visible = in_cone * in_radius;
    float final_alpha = darkness * (1.0 - clamp(visible + 0.04, 0.0, 1.0));
    COLOR = vec4(0.0, 0.0, 0.0, final_alpha);
}