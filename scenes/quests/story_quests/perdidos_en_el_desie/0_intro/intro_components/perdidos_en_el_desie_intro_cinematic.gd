# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Cinematic

@export var animation_camera: AnimationPlayer
@export var animation_environment: AnimationPlayer
@export var animation_character: AnimationPlayer


func _ready() -> void:
	_bind_animation_players()
	super._ready()


func start() -> void:
	GameState.intro_dialogue_shown = false
	super.start()


func _bind_animation_players() -> void:
	if animation_camera == null:
		animation_camera = get_node_or_null("../Camera2D/AnimationPlayer2") as AnimationPlayer
	if animation_environment == null:
		animation_environment = get_node_or_null("../OnTheGround/AnimationPlayer") as AnimationPlayer
	if animation_character == null:
		animation_character = get_node_or_null("../AnimationPlayer") as AnimationPlayer
