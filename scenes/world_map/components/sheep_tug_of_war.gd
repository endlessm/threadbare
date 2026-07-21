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


func _ready() -> void:
	# HookControl is interactive and all instances will respond
	# to user input (aiming and throwing). Remove from `hook_listener`
	# group so they don't react to user inputs.
	player_hook.remove_from_group("hook_listener")
	player_hook_2.remove_from_group("hook_listener")
	hook_control_1 = player_hook.find_child("HookControl")
	hook_control_2 = player_hook_2.find_child("HookControl")
	hook_control_1.state = HookControl.State.DISABLED
	hook_control_2.state = HookControl.State.DISABLED


func _process(_delta: float) -> void:
	# If HookControl is AIMING, cursor movement and keyboard
	# input will change the player's aim and also the sheep.
	# Disable so it only reflects on the player's aim.
	if hook_control_1.state == HookControl.State.AIMING:
		hook_control_1.state = HookControl.State.DISABLED
	if hook_control_2.state == HookControl.State.AIMING:
		hook_control_2.state = HookControl.State.DISABLED


func _on_timer_timeout() -> void:
	var sheep_options := [player_hook, player_hook_2]
	sheep_options.shuffle()
	var first_sheep: PlayerHook = sheep_options.pop_front()
	var second_sheep: PlayerHook = sheep_options.pop_front()

	first_sheep.hooked(hookable_box.find_child("HookableArea"), true)

	await get_tree().create_timer(randf_range(MIN_DELAY, MAX_DELAY)).timeout

	second_sheep.hooked(hookable_box.find_child("HookableArea"), true)
