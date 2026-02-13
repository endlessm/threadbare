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
func _walk_on_water():
	$"../TileMapLayers/Water_border".enabled = false
	#TODO do you think having the border permanently in that state is a good idea?
	#TODO you can try to come up with a way to ensure it get enabled again after a while
	
## Function to listen for user input, each key press corresponding to movement is handled here
func _unhandled_input(_event: InputEvent) -> void:
	# Set movement inputs (more options can be found in the Input Map in Project Settings)
	#var axis: Vector2 = Vector2(0,0)


# TODO:Redact parts of the blink ability so the learners can write their own.
# Blink ability

func _apply_blink():
# Convert tiles to pixels for blink distance.
	var blink_distance_pixels = blink_distance*64
# Figure out which direction to blink
	var direction := input_vector.normalized()
# Calculate new coordinates
	var target_coordinates: Vector2 = position + (direction * blink_distance_pixels)	
# Move dummy to coordinates and see if its safe to go
	$BlinkCheck.position = target_coordinates
	# Force physics
	$BlinkCheck.force_update_transform()
	# If there are no collisions, move the player to the new position.
	if not $BlinkCheck.has_overlapping_bodies():
		position = target_coordinates


# (Optional) Add a cooldown so you can’t blink every frame.
# Start a timer or use a variable that counts down.

# (Optional) Add a small visual change when blinking,
# such as a brief color change or flash.

## Function to listen for user input, each key press corresponding to movement is handled here
func _unhandled_input(_event: InputEvent) -> void:
	# Set movement inputs (more options can be found in the Input Map in Project Settings)
	
	# TODO: Full movement for debugging (remove before the script is finalized)
	var axis: Vector2 = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	# Left and right movement
	# var axis: Vector2 = Vector2(0,0)
	
	#if(Input.is_action_pressed(&"move_left")):
		#axis.x = -1
	#if(Input.is_action_pressed(&"move_right")):
		#axis.x = 1
	
	#TODO: Question: how can we make diagonal speed the same as walking in a straight line?

	# TODO: Full movement for debugging (remove before the script is finalized)
	var axis: Vector2 = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	
	if(Input.is_action_pressed(&"champ_walk_on_water")):
		_walk_on_water()
		
	
	# Blink ability
	if(Input.is_action_just_pressed(&"champ_blink")):
		_apply_blink()
	
	#TODO: Question: how can we make diagonal speed the same as walking in a straight line?


	input_vector = axis * SPEED
	
func defeat() -> void:
	if mode == Mode.DEFEATED:
		return
	
	mode = Mode.DEFEATED
	
	# Delay the respawn (If you have a defeat animation for your player, this would be how long it happens for)
	await get_tree().create_timer(2.0).timeout

	# reload current scene/checkpoint
	SceneSwitcher.reload_with_transition(Transition.Effect.FADE, Transition.Effect.FADE)
	
