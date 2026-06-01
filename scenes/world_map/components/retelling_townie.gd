# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name RetellingTownie
extends Node2D
## @experimental
##
## A character to hear the retelling at the Eternal Loom.
##
## It walks a path to join the retelling.
## It may walk a bit closer to the StoryWeaver for offering help.
## It walks the reverse path to leave.
##
## The character only appears and becomes interactible during the retelling.

## Emitted when this townie reached the Eternal Loom by walking.
signal loom_reached

## The walking path.
@export var enter_path: Path2D

var _closer_to_player_position: Vector2

@onready var townie: CharacterRandomizer = %Townie
@onready var path_walk_behavior: PathWalkBehavior = %PathWalkBehavior


## Return the reversed version of the given path.
static func reverse_path(path: Path2D) -> Path2D:
	var reversed_path := Path2D.new()
	var curve := Curve2D.new()
	var src := path.curve
	for i in range(src.point_count - 1, -1, -1):
		curve.add_point(src.get_point_position(i), src.get_point_out(i), src.get_point_in(i))
	reversed_path.curve = curve
	return reversed_path


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	hide_townie()


## Hide and deactivate the townie.
func hide_townie() -> void:
	townie.visible = false
	townie.process_mode = Node.PROCESS_MODE_DISABLED


## Walk the path to the loom and then emit [member loom_reached].
func go_to_the_loom() -> void:
	path_walk_behavior.walking_path = enter_path

	# Randomize the speed of each townie, for variation:
	path_walk_behavior.speeds = CharacterSpeeds.new()
	path_walk_behavior.speeds.walk_speed = randf_range(100, 200)

	townie.randomize_character()
	townie.visible = true
	townie.process_mode = Node.PROCESS_MODE_INHERIT
	await path_walk_behavior.ending_reached
	path_walk_behavior.process_mode = Node.PROCESS_MODE_DISABLED
	townie.velocity = Vector2.ZERO
	loom_reached.emit()


## Walk a bit closer to the StoryWeaver.
func become_helper(type: InventoryItem.ItemType) -> void:
	GameState.global.helper.obtain(type, townie.character_seed)

	var closer_path := Path2D.new()
	enter_path.add_sibling(closer_path)
	closer_path.global_position = enter_path.global_position
	var curve := Curve2D.new()
	curve.add_point(Vector2.ZERO)
	var player: Node2D = get_tree().get_first_node_in_group("player")
	_closer_to_player_position = townie.global_position.direction_to(player.global_position) * 100.0
	curve.add_point(_closer_to_player_position)
	closer_path.curve = curve

	path_walk_behavior.walking_path = closer_path
	path_walk_behavior.process_mode = Node.PROCESS_MODE_INHERIT
	await path_walk_behavior.ending_reached
	path_walk_behavior.process_mode = Node.PROCESS_MODE_DISABLED
	townie.velocity = Vector2.ZERO


## Walk the path to the loom in reverse direction, and then hide.
## If it got closer to the StoryWeaver, also consider that point for the path.
func leave_the_loom() -> void:
	var leave_path := RetellingTownie.reverse_path(enter_path)
	enter_path.add_sibling(leave_path)
	leave_path.global_position = enter_path.global_position

	if _closer_to_player_position:
		leave_path.curve.add_point(_closer_to_player_position, Vector2.ZERO, Vector2.ZERO, 0)

	path_walk_behavior.walking_path = leave_path
	path_walk_behavior.process_mode = Node.PROCESS_MODE_INHERIT
	await path_walk_behavior.ending_reached
	hide_townie()
