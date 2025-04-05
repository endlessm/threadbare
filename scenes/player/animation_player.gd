# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends AnimationPlayer

const BLOW_ANTICIPATION_TIME: float = 0.3
var cancellable: bool = false

@onready var player: Player = owner
@onready var player_fighting: Node2D = %PlayerFighting


func _process(_delta: float) -> void:
	if not player_fighting.is_fighting and current_animation != &"blow":
		cancellable = false
		_process_walk_idle(_delta)
	else:
		_process_fighting(_delta)


func _process_walk_idle(_delta: float) -> void:
	if player.velocity.is_zero_approx():
		play(&"idle")
	else:
		play(&"walk")


func _process_fighting(_delta: float) -> void:
	if current_animation == &"blow" and current_animation_position > BLOW_ANTICIPATION_TIME:
		cancellable = true

	if not player_fighting.is_fighting:
		if (
			cancellable
			and current_animation == &"blow"
			and current_animation_position <= BLOW_ANTICIPATION_TIME
		):
			stop()
		return

	if current_animation != &"blow":
		play(&"blow")
		seek(BLOW_ANTICIPATION_TIME, false, false)
