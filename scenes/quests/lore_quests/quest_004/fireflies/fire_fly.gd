# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D
## A firefly: drifts gently around its starting spot and pulses its glow on and
## off like a real one. Self-contained — needs a Sprite2D + a PointLight2D child.
## Scatter several around a dark scene for ambiance. Each one desyncs itself so
## they don't all blink in unison.

## Average drift speed (px/s); randomized ±20% per firefly.
@export var speed: float = 16.0
## How far it may wander from its starting spot before steering back (px).
@export var wander_radius: float = 80.0
## Sideways zig-zag swing (px/s). Higher = wider zig-zag.
@export var zigzag_amplitude: float = 45.0
## How fast it zig-zags. Higher = tighter, sharper zig-zag.
@export var zigzag_frequency: float = 6.0
## Seconds for one glow cycle (randomized per firefly around this).
@export var glow_period: float = 3.0
## Peak light energy when fully lit.
@export var glow_energy: float = 1.2
## Firefly tint (body + light).
@export var glow_color: Color = Color(0.95, 1.0, 0.5)

@onready var _light: PointLight2D = $PointLight2D
@onready var _sprite: Sprite2D = $Sprite2D

var _home: Vector2
var _direction: Vector2
var _t: float = 0.0
var _dir_timer: float = 0.0
var _glow_t: float = 0.0
var _cycle: float


func _ready() -> void:
	_home = position
	_direction = Vector2.from_angle(randf() * TAU)
	speed = randf_range(speed * 0.8, speed * 1.2)
	_cycle = randf_range(glow_period * 0.8, glow_period * 1.3)
	# Desync each firefly so they don't blink together.
	_glow_t = randf() * _cycle
	_t = randf() * TAU
	if _sprite:
		_sprite.modulate = glow_color
	if _light:
		_light.color = glow_color


func _process(delta: float) -> void:
	_t += delta
	_dir_timer += delta
	_glow_t += delta

	_move(delta)

	if _dir_timer > randf_range(1.0, 2.0):
		_direction = _direction.rotated(randf_range(-1.0, 1.0))
		if randf() < 0.2:
			_direction = Vector2.from_angle(randf() * TAU)
		_dir_timer = 0.0

	_glow()


func _move(delta: float) -> void:
	# Steer back home if it wandered too far.
	if _home.distance_to(position) > wander_radius:
		_direction = position.direction_to(_home).rotated(randf_range(-0.3, 0.3))
	# Forward drift + a perpendicular sine swing = zig-zag flight.
	var sideways := _direction.orthogonal() * sin(_t * zigzag_frequency) * zigzag_amplitude
	position += (_direction * speed + sideways) * delta


func _glow() -> void:
	if _glow_t >= _cycle:
		_glow_t = 0.0
		_cycle = randf_range(glow_period * 0.8, glow_period * 1.3)

	var p := _glow_t / _cycle
	var b := 0.0
	if p < 0.1:
		b = p / 0.1                       # quick fade in
	elif p < 0.3:
		b = 1.0                           # full glow
	elif p < 0.5:
		b = 1.0 - (p - 0.3) / 0.2         # fade out
	else:
		b = 0.0                           # dark most of the cycle
		if randf() < 0.04:
			b = randf_range(0.1, 0.3)     # occasional faint sparkle

	if _light:
		_light.energy = b * glow_energy
	if _sprite:
		_sprite.modulate.a = b
