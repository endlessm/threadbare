# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name BounceWalkBehavior
extends BaseCharacterBehavior
## @experimental
##
## Make the character move and bounce on walls.
##
## The character bounces when it is colliding with a wall and moving slower than
## the [member CharacterSpeeds.bounce_speed] configured in [member speeds].

## Emitted when [member direction] is updated.
signal direction_changed

## Parameters controlling the speed at which this character walks. If unset, the default values of
## [CharacterSpeeds] are used.
@export var speeds: CharacterSpeeds

## If set, ignore the [member initial_angle] and pick a random one instead.
@export var pick_random_initial_angle: bool = false:
	set(value):
		pick_random_initial_angle = value
		notify_property_list_changed()

## Angle of the initial direction.
@export_range(0, 360, 1, "radians_as_degrees") var initial_angle: float = PI / 4.0

## The current direction as a unit Vector2.
var direction: Vector2


func _validate_property(property: Dictionary) -> void:
	if property.name == "initial_angle" and pick_random_initial_angle:
		property.usage |= PROPERTY_USAGE_READ_ONLY


func _update_direction() -> void:
	if not direction:
		direction = Vector2.from_angle(
			randf_range(0, TAU) if pick_random_initial_angle else initial_angle
		)
		direction_changed.emit()
	elif character.is_on_wall():
		direction = direction.bounce(character.get_wall_normal())
		direction_changed.emit()


func _ready() -> void:
	if Engine.is_editor_hint():
		set_physics_process(false)
		return

	if not speeds:
		speeds = CharacterSpeeds.new()

	_update_direction()


func _physics_process(_delta: float) -> void:
	if not direction:
		_update_direction()

	character.velocity = direction * speeds.walk_speed
	var collided := character.move_and_slide()

	if collided and character.is_on_wall():
		if speeds.is_stuck(character):
			_update_direction()
