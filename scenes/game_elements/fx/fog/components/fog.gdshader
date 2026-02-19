shader_type canvas_item;

/**
 * Use a Simplex noise for a dynamic texture. Or provide your own grayscale tileable texture!
 */
uniform sampler2D fog_texture: filter_nearest, repeat_enable;

/**
 * How much dense is the fog.
 * This parameter could be animated!
 */
uniform float density: hint_range(1.0, 10.0) = 3.0;

/**
 * Animate the fog.
 * A vertical velocity emphasizes the fog elevating.
 */
uniform vec2 speed = vec2(0.0,0.01);

/**
 * How much alpha, maximum.
 * With a value of 1 the fog can reach full white.
 */
uniform float alpha: hint_range(0.0, 1.0) = 0.6;

void fragment() {
	vec2 uv = UV + speed * TIME;
	float fog = texture(fog_texture, uv).r;
	fog = smoothstep(1.0/density, 1.0, fog);
	COLOR.a *= alpha * fog;
}
