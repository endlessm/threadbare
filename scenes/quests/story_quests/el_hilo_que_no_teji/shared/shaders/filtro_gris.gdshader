// SPDX-FileCopyrightText: The Threadbare Authors
// SPDX-License-Identifier: MPL-2.0
shader_type canvas_item;

const vec3 LUMINANCIA = vec3(0.299, 0.587, 0.114);

// 0 = con su color; 1 = totalmente gris.
uniform float nivel_gris : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    // COLOR ya trae el modulate del sprite: así el parpadeo de invulnerabilidad
    // se ve aunque Lino esté gris.
    float gris_puro = dot(COLOR.rgb, LUMINANCIA);
    COLOR.rgb = mix(COLOR.rgb, vec3(gris_puro), nivel_gris);
}