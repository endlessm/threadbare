# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CharacterBody2D

const SPEED = 300.0
var input_vector: Vector2


## Controls how the player can interact with the world around them.
enum Mode {
	## Player can explore the world, interact with items and NPCs, but is not
	## engaged in combat. Combat actions are not available in this mode.
	COZY,
	## Player can't be controlled anymore.
	DEFEATED,
}
var mode: Mode = Mode.COZY

## How fast does the player transition from walking/running to stopped.
## A low value will make the character look as slipping on ice.
## A high value will stop the character immediately.
@export_range(10, 100000, 10) var stopping_step: float = 1500.0

## How fast does the player transition from stopped to walking/running.
@export_range(10, 100000, 10) var moving_step: float = 4000.0

## How many 64px tiles the player should teleport when the blink key (c) is pressed.
@export_range(0,24,0.5,"suffix:tiles") var blink_distance = 3.0


## Function that is called every "tick" that is constantly listening
func _physics_process(delta: float) -> void:
	# Don't let player move once defeated
	if mode == Mode.DEFEATED:
		velocity = Vector2.ZERO
		return
	
	# Handle stopping and moving
	var step := (
		stopping_step if velocity.length_squared() > input_vector.length_squared() else moving_step
	)
	
	# Change speed of player
	velocity = velocity.move_toward(input_vector, step * delta)
	move_and_slide()

# Blink ability
func _apply_blink() -> void:
	# If player is defeated, do nothing.
	if mode == Mode.DEFEATED:
		return
# Convert tiles to pixels for blink distance
	var blink_distance_pixels = blink_distance*64
# Figure out where to blink
	var blink_direction := input_vector.normalized()
	var target_coordinates: Vector2 = global_position # Missing parts of calculation!	
# Move dummy to coordinates and force physics update
	var dummy := $BlinkCheck
	dummy.global_position = target_coordinates
	dummy.force_update_transform()
# Show visual
	$BlinkCheck/Sprite2D.show()
# Delay is for visuals and to allow time for physics to update
	await get_tree().create_timer(0.1).timeout
# Ensure dummy is within bounds
	if $"../Bounds/Blink Bounds".overlaps_area(dummy):
	# If there are no collisions, move the player to the new position.
		if not dummy.has_overlapping_bodies():
			#TODO: Teleport the player instantly to the desired location
			return
			
	# Reset dummy
	$BlinkCheck.global_position = global_position
	$BlinkCheck/Sprite2D.hide()

	# TODO: (Optional) Add a cooldown so you can’t blink every frame.
	# Start a timer or use a variable that counts down.

	# TODO: (Optional) Add a small visual change when blinking,
	# such as a brief color change or flash.


## Function to remove collisions, allowing the player to walk on water tiles
func _walk_on_water() -> void:
	#remove the collision of the Water_border, allowing player to "walk" on "water"
	$"../TileMapLayers/Water_border".enabled = false
	# TODO do you think having the border permanently in that state is a good idea?
	# TODO you can try to come up with a way to ensure it get enabled again after a while
	# TODO (Optional) add a visual indicator that the function was activated

## Function to listen for user input, each key press corresponding to movement is handled here
func _unhandled_input(_event: InputEvent) -> void:
	# Set movement inputs (more options can be found in the Input Map in Project Settings)
	# Left and right movement
	var axis: Vector2 = Vector2(0,0)

	if(Input.is_action_pressed(&"move_left")):
		axis.x = -1
	if(Input.is_action_pressed(&"move_right")):
		axis.x = 1
	input_vector = axis * SPEED
	# TODO: how can we make the character walk up and down?
 	# TODO:  how can we make diagonal speed the same as walking in a straight line?
	
	# Blink ability
	if(Input.is_action_just_pressed(&"champ_blink")):
		_apply_blink()
	# Walk on water ability
	if(Input.is_action_pressed(&"champ_walk_on_water")):
		_walk_on_water()
	
	
func defeat() -> void:
	if mode == Mode.DEFEATED:
		return
	
	mode = Mode.DEFEATED
	
	
	# Delay the respawn (If you have a defeat animation for your player, this would be how long it happens for)
	await get_tree().create_timer(2.0).timeout

	# reload current scene/checkpoint
	SceneSwitcher.reload_with_transition(Transition.Effect.FADE, Transition.Effect.FADE)
	
