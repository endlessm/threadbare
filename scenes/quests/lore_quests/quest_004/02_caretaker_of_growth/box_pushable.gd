# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CharacterBody2D
## Pushable Sokoban rock: moves cell by cell when pushed by the player.
## Shakes while sliding (via menhir_tremble shader) for visual feedback.
## Grouped in "pushable_box" so [PressurePlate] can detect it.

## Grid cell size in pixels.
@export var cell_size: float = 64.0
## Step duration in seconds.
@export var step_time: float = 0.12
## Shake intensity during movement.
@export var tremble_amplitude: float = 1.0

var _moving: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var push_sensor: Area2D = $PushSensor


func _ready() -> void:
	add_to_group(&"pushable_box")
	# Duplicate material to prevent all rocks from shaking at once.
	if sprite.material:
		sprite.material = sprite.material.duplicate()
	_set_tremble(0.0)


func _physics_process(_delta: float) -> void:
	if _moving:
		return

	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if player == null or not push_sensor.overlaps_body(player):
		return

	# Read directional input intent.
	var input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if input.length() < 0.5:
		return

	var dir := _cardinal(input)
	# Only push if player presses TOWARDS the rock.
	if (global_position - player.global_position).dot(dir) <= 0.0:
		return

	var step := dir * cell_size
	# Cancel if target cell is blocked.
	if test_move(global_transform, step):
		return

	_step_to(global_position + step)


## Reduces input vector to the main cardinal direction.
func _cardinal(v: Vector2) -> Vector2:
	if absf(v.x) >= absf(v.y):
		return Vector2(signf(v.x), 0.0)
	return Vector2(0.0, signf(v.y))


func _step_to(target: Vector2) -> void:
	_moving = true
	_set_tremble(tremble_amplitude)
	var tween := create_tween()
	tween.tween_property(self, "global_position", target, step_time)
	tween.tween_callback(_finish_step)


func _finish_step() -> void:
	_moving = false
	_set_tremble(0.0)


func _set_tremble(amount: float) -> void:
	if sprite.material is ShaderMaterial:
		(sprite.material as ShaderMaterial).set_shader_parameter(&"amplitude", amount)
