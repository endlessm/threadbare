shader_type canvas_item;
uniform float speed = 0.1;

void fragment() {
    vec2 uv = UV;
    uv.x += TIME * speed;
    uv.y += TIME * speed;
    COLOR = texture(TEXTURE, uv);
}