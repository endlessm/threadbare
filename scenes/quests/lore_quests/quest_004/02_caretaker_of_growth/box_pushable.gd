# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CharacterBody2D

@export var cell_size: float = 64.0

@export var step_time: float = 0.12

@export var tremble_amplitude: float = 1.0

var _moving: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var push_sensor: Area2D = $PushSensor
@onready var hookable_area: HookableArea = $HookableArea


func _ready() -> void:
	add_to_group(&"pushable_box")

	if sprite.material:
		sprite.material = sprite.material.duplicate()
	_set_tremble(0.0)


func _physics_process(_delta: float) -> void:
	if _moving:
		return

	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if player == null or not push_sensor.overlaps_body(player):
		return

	var input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if input.length() < 0.5:
		return

	var dir := _cardinal(input)

	if (global_position - player.global_position).dot(dir) <= 0.0:
		return

	var step := dir * cell_size

	if test_move(global_transform, step):
		return

	_step_to(global_position + step)


func _cardinal(v: Vector2) -> Vector2:
	if absf(v.x) >= absf(v.y):
		return Vector2(signf(v.x), 0.0)
	return Vector2(0.0, signf(v.y))


func _try_step(direction: Vector2) -> bool:
	if _moving:
		return false
	var step := _cardinal(direction) * cell_size
	if test_move(global_transform, step):
		return false
	_step_to(global_position + step)
	return true


func got_repelled(direction: Vector2) -> void:
	_try_step(direction)


func got_pulled(direction: Vector2) -> void:
	if _try_step(direction):
		await get_tree().create_timer(step_time).timeout
		hookable_area.release_from_pull()
	else:
		hookable_area.release_from_pull(true)


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
