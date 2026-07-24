# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@onready var animation_player: AnimationPlayer = %AnimationPlayer

@onready var shaker: Shaker = %Shaker


func _ready() -> void:
	await get_tree().create_timer(2.).timeout
	shaker.shake()
	animation_player.play("reweaven")
	await animation_player.animation_finished
	SceneSwitcher.reload_with_transition(Transition.Effect.FADE, Transition.Effect.FADE)
