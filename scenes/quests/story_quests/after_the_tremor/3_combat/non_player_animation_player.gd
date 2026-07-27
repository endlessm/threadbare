# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends AnimationPlayer

@onready var player_sprite: AnimatedSprite2D = %PlayerSprite
@onready var player_repel: PlayerRepel = $"../PlayerRepel"
@onready var original_speed_scale: float = speed_scale

func _ready() -> void:
	animation_finished.connect(_on_animation_finished)
	player_repel.repelling_changed.connect(_on_player_repel_repelling_changed)

# Stationary as long as it isn't mid animation
func _process(_delta: float) -> void:
	if current_animation in [&"repel", &"throw_string"]:
		return
		
	play(&"idle")
	

func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name == &"repel" and player_repel.repelling:
		speed_scale = original_speed_scale
		play(&"repel")

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
	seek(player_repel.REPEL_ANTICIPATION_TIME, false, false)
