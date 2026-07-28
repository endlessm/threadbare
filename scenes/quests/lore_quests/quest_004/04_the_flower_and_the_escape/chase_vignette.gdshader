// SPDX-FileCopyrightText: The Threadbare Authors
// SPDX-License-Identifier: MPL-2.0
// Viñeta roja pulsante en los bordes (tensión de persecución). El centro queda
// limpio; los bordes se tiñen de rojo y "laten". La fuerza la controla `intensity`
// (0 = invisible, 1 = full) que el script sube al perseguir y baja al terminar.
shader_type canvas_item;

uniform vec4 tint : source_color = vec4(0.72, 0.03, 0.03, 1.0);
uniform float intensity = 0.0;     // 0..1, animado por el script
uniform float inner = 0.30;        // desde dónde (centro->borde) empieza el rojo
uniform float outer = 0.92;        // dónde llega a full
uniform float pulse_speed = 3.5;   // latido
uniform float pulse_amount = 0.22; // cuánto late

void fragment() {
	vec2 d = UV - vec2(0.5);
	float dist = length(d) * 1.41421356;       // ~0 centro, ~1 esquina
	float v = smoothstep(inner, outer, dist);
	float pulse = 1.0 + sin(TIME * pulse_speed) * pulse_amount;
	COLOR = vec4(tint.rgb, clamp(v * intensity * pulse, 0.0, 1.0) * tint.a);
}
