// SPDX-FileCopyrightText: The Threadbare Authors
// SPDX-License-Identifier: MPL-2.0
shader_type canvas_item;
// Como mi_filtro_saturacion, pero con menos color y menos contraste,
// para que las rocas no llamen tanto la atención.

const vec3 LUMINANCIA = vec3(0.299, 0.587, 0.114);

uniform float saturation : hint_range(0.0, 1.0) = 0.1;
uniform float contrast : hint_range(0.0, 1.0) = 0.6;
uniform float darkness_factor : hint_range(0.0, 1.0) = 0.6;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	float gray = dot(tex_color.rgb, LUMINANCIA);
	vec3 color = mix(vec3(gray), tex_color.rgb, saturation);
	color = mix(vec3(0.5), color, contrast);
	COLOR.rgb = color * darkness_factor;
	COLOR.a = tex_color.a;
}
