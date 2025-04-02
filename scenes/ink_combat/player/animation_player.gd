# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends AnimationPlayer

const FIGHT_ANIMATIONS: Array[StringName] = [&"blow_right", &"blow_left", &"blow_up", &"blow_down"]
var cancellable: bool = false

@onready var player: FightingPlayer = owner
@onready var player_fighting: Node2D = %PlayerFighting


func _process_fighting() -> void:
	if current_animation in FIGHT_ANIMATIONS and current_animation_position > 0.3:
		cancellable = true

	if not player_fighting.is_fighting:
		if (
			cancellable
			and current_animation in FIGHT_ANIMATIONS
			and current_animation_position <= 0.3
		):
			stop()
		return

	if player_fighting.is_fighting:
		var angle: float = player.last_nonzero_axis.angle()
		if abs(-PI / 2 - angle) <= PI / 4:
			play(&"blow_up")
		elif abs(PI / 2 - angle) <= PI / 4:
			play(&"blow_down")
		elif abs(PI - angle) <= PI / 4:
			play(&"blow_left")
		elif abs(angle) <= PI / 4:
			play(&"blow_right")


func _process(_delta: float) -> void:
	if player_fighting.is_fighting or current_animation in FIGHT_ANIMATIONS:
		_process_fighting()
		return
	cancellable = false

	if player.velocity.is_zero_approx():
		play(&"idle")
	else:
		play(&"walk")
