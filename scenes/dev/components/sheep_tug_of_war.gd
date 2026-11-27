# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

const MIN_DELAY: float = 0.5
const MAX_DELAY: float = 3

@onready var player_hook: PlayerHook = $TuggingSheep/Sheep/PlayerHook
@onready var player_hook_2: PlayerHook = $TuggingSheep/Sheep2/PlayerHook2
@onready var hookable_box: AnimatableBody2D = $HookableBox
@onready var hookable_area: HookableArea = hookable_box.find_child("HookableArea")


func _ready() -> void:
	# The sheep grappling hooks have player_controlled off, so they ignore the
	# input. Point them at the box while they wait to throw.
	player_hook.aim_at(hookable_area.get_anchor_position())
	player_hook_2.aim_at(hookable_area.get_anchor_position())


func _on_timer_timeout() -> void:
	var sheep_options := [player_hook, player_hook_2]
	sheep_options.shuffle()
	var first_sheep: PlayerHook = sheep_options.pop_front()
	var second_sheep: PlayerHook = sheep_options.pop_front()

	_throw_at_box(first_sheep)

	await get_tree().create_timer(randf_range(MIN_DELAY, MAX_DELAY)).timeout

	_throw_at_box(second_sheep)


func _throw_at_box(sheep_hook: PlayerHook) -> void:
	sheep_hook.aim_at(hookable_area.get_anchor_position())
	sheep_hook.throw_once()
