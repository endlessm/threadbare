extends CharacterBody2D

#const DEFAULT_SPRITE_FRAME: SpriteFrames = preload("uid://vwf8e1v8brdp")

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
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


#func _ready() -> void:
	#self.sprite_frames = DEFAULT_SPRITE_FRAME

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
	
func _unhandled_input(_event: InputEvent) -> void:
	# Set movement inputs (more options can be found in the Input Map in Project Settings)
	# Question: how can we make diagonal speed the same as walking in a straight line?
	
	# Something like this will be used for learners (limiting movement)
	#var axis: Vector2 = Vector2(0,0)
	#if(Input.is_action_pressed(&"move_left")):
		#axis.x = -1
	#if(Input.is_action_pressed(&"move_right")):
		#axis.x = 1
		
	# This is only for debugging
	var axis: Vector2 = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")

	input_vector = axis * SPEED
	
func defeat() -> void:
	if mode == Mode.DEFEATED:
		return
	
	mode = Mode.DEFEATED
	
	# Delay the respawn (If you have a defeat animation for your player, this would be how long it happens for)
	await get_tree().create_timer(2.0).timeout

	# reload current scene/checkpoint
	SceneSwitcher.reload_with_transition(Transition.Effect.FADE, Transition.Effect.FADE)
	
