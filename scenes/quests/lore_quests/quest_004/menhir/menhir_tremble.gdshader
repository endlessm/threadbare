// SPDX-FileCopyrightText: The Threadbare Authors
// SPDX-License-Identifier: MPL-2.0
shader_type canvas_item;

// Píxeles de temblor (0 = quieto). El script lo sube mientras el menhir sube.
uniform float amplitude : hint_range(0.0, 8.0) = 0.0;
// Qué tan rápido vibra.
uniform float frequency = 30.0;

void vertex() {
	float t = TIME * frequency;
	VERTEX.x += sin(t) * amplitude;
	VERTEX.y += sin(t * 1.7 + 1.3) * amplitude * 0.5;
}