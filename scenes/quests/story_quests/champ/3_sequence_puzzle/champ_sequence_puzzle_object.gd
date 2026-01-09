# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool 
class_name ChampSequencePuzzleObject
extends SequencePuzzleObject

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var rock: AnimatedSprite2D = %AnimatedSprite2D

var _idle_animation := &"default"

## Makes the rock passable, and displays a dry idle state.
func dry_off() -> void:
	_idle_animation = &"dry"
	collision.disabled = true

# Overrides superclass to make idle animation dynamic
func _stop() -> void:
	if animated_sprite.is_playing() and animated_sprite.animation == "struck":
		await animated_sprite.animation_looped
		animated_sprite.play(_idle_animation)

## Submerges the rock and prevents further interactions with it.
func submerge() -> void:
	rock.play(&"default")
	interact_area.disabled = true
