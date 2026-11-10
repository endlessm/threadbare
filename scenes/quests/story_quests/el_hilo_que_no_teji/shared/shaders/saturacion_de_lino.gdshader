// SPDX-FileCopyrightText: The Threadbare Authors
// SPDX-License-Identifier: MPL-2.0
shader_type canvas_item;
// Como mi_filtro_saturacion.gdshader, pero respetando el modulate del sprite,
// para poder oscurecer y desvanecer a Lino mientras pierde el color.

const vec3 LUMINANCIA = vec3(0.299, 0.587, 0.114);

// 1 = con todo su color; 0 = gris.
uniform float saturation : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	float gris = dot(COLOR.rgb, LUMINANCIA);
	COLOR.rgb = mix(vec3(gris), COLOR.rgb, saturation);
}
