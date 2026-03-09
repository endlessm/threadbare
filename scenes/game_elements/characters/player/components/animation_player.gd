# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends AnimationPlayer

const REPEL_ANTICIPATION_TIME: float = 0.3

@onready var player: Player = owner
@onready var player_sprite: AnimatedSprite2D = %PlayerSprite
@onready var player_repel: PlayerRepel = %PlayerRepel
@onready var player_hook: PlayerHook = %PlayerHook
@onready var original_speed_scale: float = speed_scale


func _ready() -> void:
	animation_finished.connect(_on_animation_finished)
	player.mode_changed.connect(_on_player_mode_changed)
	player_repel.repelling_changed.connect(_on_player_repel_repelling_changed)
	player_hook.string_thrown.connect(_on_player_hook_string_thrown)


func _process(_delta: float) -> void:
	if player.mode == player.Mode.DEFEATED:
		return
	if current_animation in [&"repel", &"throw_string"]:
		return

	if player.velocity.is_zero_approx():
		play(&"idle")
	elif player_sprite.sprite_frames.has_animation(&"run") and player.is_running():
		play(&"run")
	else:
		play(&"walk")

	var double_speed: bool = current_animation == &"walk" and player.is_running()
	speed_scale = original_speed_scale * (2.0 if double_speed else 1.0)


func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name == &"repel" and player_repel.repelling:
		speed_scale = original_speed_scale
		play(&"repel")


func _on_player_mode_changed(mode: Player.Mode) -> void:
	match player.mode:
		Player.Mode.DEFEATED:
			speed_scale = original_speed_scale
			play(&"defeated")


func _on_player_repel_repelling_changed(repelling: bool) -> void:
	if not repelling:
		return

	# The repel animation is already ongoing. Prevent starting it again by smashing the buttons.
	if current_animation == &"repel":
		return

	# Repel animation is being played for the first time. So skip the anticipation and go
	# directly to the action.
	speed_scale = original_speed_scale
	play(&"repel")
	seek(REPEL_ANTICIPATION_TIME, false, false)


func _on_player_hook_string_thrown() -> void:
	# A new throw action (blading sword) interrupts the previous one.
	if current_animation == &"throw_string":
		stop()
	speed_scale = original_speed_scale
	play(&"throw_string")
