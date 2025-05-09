# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends AnimationPlayer

const BLOW_ANTICIPATION_TIME: float = 0.3

@onready var player: Player = owner
@onready var player_fighting: Node2D = %PlayerFighting
@onready var original_speed_scale: float = speed_scale


func _process(_delta: float) -> void:
	match player.mode:
		Player.Mode.COZY:
			_process_walk_idle(_delta)
		Player.Mode.FIGHTING:
			_process_fighting(_delta)

	var double_speed: bool = current_animation == &"walk" and player.is_running()
	speed_scale = original_speed_scale * (2.0 if double_speed else 1.0)


func _process_walk_idle(_delta: float) -> void:
	if player.velocity.is_zero_approx():
		play(&"idle")
	else:
		play(&"walk")


func _process_fighting(delta: float) -> void:
	if not player_fighting.is_fighting:
		# If the current animation is blow and it has passed the anticipation
		# phase, it plays until the end.
		if not (
			current_animation == &"blow" and current_animation_position > BLOW_ANTICIPATION_TIME
		):
			_process_walk_idle(delta)
		return

	if current_animation != &"blow":
		# Fighting animation is being played for the first time. So skip the anticipation and go
		# directly to the action.
		play(&"blow")
		seek(BLOW_ANTICIPATION_TIME, false, false)
