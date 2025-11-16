@tool
extends "res://scenes/game_elements/characters/player/components/player.gd"
## Custom player configuration for Wizzy Quest
##
## Applies custom scale and initial position offset specific to Wizzy Quest gameplay.
## The defeat animation logic is handled by wizzy_stealth_game_logic.gd.

## Visual scale factor for the player sprite
@export var custom_scale: Vector2 = Vector2(0.8, 0.8)

## Initial position offset (Vector2.ZERO means no offset)
@export var custom_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	super._ready()
	
	# Apply custom scale
	#scale = custom_scale
	
	# Apply position offset if specified
	#if custom_position != Vector2.ZERO:
		#position = custom_position
