# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name ErraticWalkBehavior
extends BaseCharacterBehavior
## @experimental
##
## Make the character walk around erratically.
##
## The character changes direction after traveling [member travel_distance],
## or when it gets stuck colliding with something.

## Emitted when [member character] got stuck while walking.
signal got_stuck

## Emitted when [member direction] is updated.
signal direction_changed

## Parameters controlling the speed at which this character walks. If unset, the default values of
## [CharacterSpeeds] are used.
@export var speeds: CharacterSpeeds

## The turn direction will be randomly picked between this and [member turn_angle_right].
@export_range(0, 180, 1, "radians_as_degrees") var turn_angle_left: float = PI / 2.0

## The turn direction will be randomly picked between [member turn_angle_left] and this.
@export_range(0, 180, 1, "radians_as_degrees") var turn_angle_right: float = PI / 2.0

## The distance to travel between turns.
## If zero, the character will turn around all the time.
@export_range(0, 800, 1, "or_greater", "suffix:m") var travel_distance: float = 400.0

## How smooth or sharp is the change of direction.
## Close to zero: smooth.
## Close to one: sharp (immediate).
@export_range(0.1, 1.0, 0.1, "suffix:m") var direction_weight: float = 0.2

## The current walking direction.
var direction: Vector2

## The current distance travelled since last turn.
var distance: float = 0


func _update_direction() -> void:
	if not direction:
		direction = Vector2.from_angle(randf_range(0, TAU))
	else:
		direction = direction.rotated(randf_range(-turn_angle_left, turn_angle_right))
	direction_changed.emit()


func _ready() -> void:
	if Engine.is_editor_hint():
		set_physics_process(false)
		return

	if not speeds:
		speeds = CharacterSpeeds.new()


func _physics_process(delta: float) -> void:
	if not direction:
		_update_direction()

	character.velocity = character.velocity.lerp(direction * speeds.walk_speed, direction_weight)
	var collided := character.move_and_slide()
	if collided and character.is_on_wall():
		if speeds.is_stuck(character):
			got_stuck.emit()
			_update_direction()
			distance = 0.0
	else:
		distance += speeds.walk_speed * delta
		if distance > travel_distance:
			_update_direction()
			distance = 0.0
