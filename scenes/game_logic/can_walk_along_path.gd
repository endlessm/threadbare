# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool

## Make the character walk along a path.
class_name CanWalkAlongPath
extends Node2D

@export var walking_path: Path2D:
	set = _set_walking_path

@export_range(5, 300, 5, "or_greater", "or_less", "suffix:m/s") var walk_speed: float = 250.0

var _initial_position: Vector2

# For going back and forth an open path.
var _direction: int = 1

# TODO: Add configuration warning to the node if the owner is not a Character.
@onready var character: Character = get_parent()


func _ready() -> void:
	if Engine.is_editor_hint():
		set_physics_process(false)
		return

	print("%s: I can walk along a path" % character.name)

	_set_walking_path(walking_path)

	if not character.is_node_ready():
		await character.ready
	character.animated_sprite_2d.play(&"walk")
	_update_character_facing()


func _set_walking_path(new_walking_path: Path2D) -> void:
	walking_path = new_walking_path
	update_configuration_warnings()
	if not is_node_ready():
		return
	if walking_path:
		_put_character_in_path()


func _get_configuration_warnings() -> PackedStringArray:
	if not walking_path:
		return ["A walking path must be set."]
	return []


func _put_character_in_path() -> void:
	character.position = walking_path.position + walking_path.curve.get_point_position(0)
	_initial_position = character.position


func _update_character_facing() -> void:
	character.look_at_side = Enums.LookAtSide.LEFT if _direction == -1 else Enums.LookAtSide.RIGHT


func _physics_process(delta: float) -> void:
	var closest_offset := walking_path.curve.get_closest_offset(
		character.position - _initial_position
	)
	var new_offset := closest_offset + walk_speed * delta * _direction
	if new_offset > walking_path.curve.get_baked_length() or new_offset < 0.0:
		_direction *= -1
	var point_position: Vector2 = walking_path.curve.sample_baked(new_offset)
	character.velocity = (
		character.position.direction_to(_initial_position + point_position) * walk_speed
	)
	character.move_and_slide()
	_update_character_facing()
