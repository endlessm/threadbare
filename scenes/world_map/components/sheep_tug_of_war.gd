# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

const MIN_DELAY: float = 0.5
const MAX_DELAY: float = 3

var hook_control_1: Node2D
var hook_control_2: Node2D

@onready var player_hook: PlayerHook = $TuggingSheep/Sheep/PlayerHook
@onready var player_hook_2: PlayerHook = $TuggingSheep/Sheep2/PlayerHook2
@onready var hookable_box: AnimatableBody2D = $HookableBox


## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player_hook.remove_from_group("hook_listener")
	player_hook_2.remove_from_group("hook_listener")
	hook_control_1 = player_hook.find_child("HookControl")
	hook_control_2 = player_hook_2.find_child("HookControl")
	hook_control_1.state = 0
	hook_control_2.state = 0


## Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# TODO: Better way to avoid getting input from player aim/controls?
	if hook_control_1.state == 1:
		hook_control_1.state = 0
	if hook_control_2.state == 1:
		hook_control_2.state = 0


func _on_timer_timeout() -> void:
	var sheep_options := [player_hook, player_hook_2]
	sheep_options.shuffle()
	var first_sheep: PlayerHook = sheep_options.pop_front()
	var second_sheep: PlayerHook = sheep_options.pop_front()

	first_sheep.hooked(hookable_box.find_child("HookableArea"), true)

	await get_tree().create_timer(max(randf() * MAX_DELAY, MIN_DELAY)).timeout

	second_sheep.hooked(hookable_box.find_child("HookableArea"), true)
