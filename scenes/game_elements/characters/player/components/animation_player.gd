# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends AnimationPlayer

const REPEL_ANTICIPATION_TIME: float = 0.3

@onready var player: Player = owner
@onready var player_sprite: AnimatedSprite2D = %PlayerSprite
@onready var player_fighting: Node2D = %PlayerFighting
@onready var player_hook: Node2D = %PlayerHook
@onready var original_speed_scale: float = speed_scale


func _ready() -> void:
	player.mode_changed.connect(_on_player_mode_changed)
	player_hook.string_thrown.connect(_on_player_hook_string_thrown)


func _process(_delta: float) -> void:
	match player.mode:
		Player.Mode.COZY:
			_process_walk_idle(_delta)
		Player.Mode.FIGHTING:
			_process_fighting(_delta)
		Player.Mode.HOOKING:
			_process_hooking(_delta)

	var double_speed: bool = current_animation == &"walk" and player.is_running()
	speed_scale = original_speed_scale * (2.0 if double_speed else 1.0)


func _get_repel_animation() -> StringName:
	if not player_sprite.sprite_frames.has_animation(&"attack_02"):
		return &"repel_deprecated"
	return &"repel"


func _process_walk_idle(_delta: float) -> void:
	if player.velocity.is_zero_approx():
		play(&"idle")
	elif player_sprite.sprite_frames.has_animation(&"run") and player.is_running():
		play(&"run")
	else:
		play(&"walk")


func _process_fighting(delta: float) -> void:
	var repel: StringName = _get_repel_animation()
	if not player_fighting.is_fighting:
		# If the current animation is repel and it has passed the anticipation
		# phase, it plays until the end.
		if not (
			current_animation == repel and current_animation_position > REPEL_ANTICIPATION_TIME
		):
			_process_walk_idle(delta)
		return

	if current_animation != repel:
		# Fighting animation is being played for the first time. So skip the anticipation and go
		# directly to the action.
		play(repel)
		seek(REPEL_ANTICIPATION_TIME, false, false)


func _process_hooking(delta: float) -> void:
	if current_animation == &"throw_string":
		return

	_process_walk_idle(delta)


func _on_player_mode_changed(mode: Player.Mode) -> void:
	match player.mode:
		Player.Mode.DEFEATED:
			play(&"defeated")


func _on_player_hook_string_thrown() -> void:
	if current_animation == &"throw_string":
		stop()
	play(&"throw_string")
