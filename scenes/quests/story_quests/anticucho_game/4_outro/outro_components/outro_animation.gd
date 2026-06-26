# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@export_file("*.tscn") var next_scene: String = "uid://cufkthb25mpxy"

@export var animation_name: StringName = &"outro"

@onready var animated_sprite: AnimatedSprite2D = %AnimatedSprite2D


func _ready() -> void:
	get_viewport().size_changed.connect(_fit_to_screen)
	_fit_to_screen()
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.play(animation_name)


func _fit_to_screen() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var frame_texture := animated_sprite.sprite_frames.get_frame_texture(animation_name, 0)
	var frame_size := frame_texture.get_size()
	var cover_scale: float = maxf(
		viewport_size.x / frame_size.x, viewport_size.y / frame_size.y
	)
	animated_sprite.scale = Vector2(cover_scale, cover_scale)
	animated_sprite.position = viewport_size / 2.0


func _on_animation_finished() -> void:
	if next_scene:
		(
			SceneSwitcher
			. change_to_file_with_transition(
				next_scene,
				^"",
				Transition.Effect.FADE,
				Transition.Effect.FADE,
			)
		)
