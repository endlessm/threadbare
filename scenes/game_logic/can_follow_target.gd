# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool

## FIXME: Make the character follow a target.
class_name CanFollowTarget
extends Node2D

signal target_reached

@export_range(5, 300, 5, "or_greater", "or_less", "suffix:m/s") var walk_speed: float = 250.0

@export_range(0.1, 10.0, 0.1, "or_greater", "or_less", "suffix:s")
var update_target_time: float = 0.5

@export var node_to_follow: Node2D:
	set = _set_node_to_follow

var _update_target_timer: Timer = Timer.new()
var _target_position: Vector2

# TODO: Add configuration warning to the node if the parent is not a Character.
@onready var character: Character = get_parent()


func _ready() -> void:
	if Engine.is_editor_hint():
		set_physics_process(false)
		return

	print("%s: I can follow a target" % character.name)

	_set_node_to_follow(node_to_follow)
	_update_target_timer.wait_time = update_target_time
	_update_target_timer.timeout.connect(_update_target_position)
	add_child(_update_target_timer)
	_update_target_timer.start()

	if not character.is_node_ready():
		await character.ready
	character.animated_sprite_2d.play(&"walk")


func _set_node_to_follow(new_node_to_follow: Node2D) -> void:
	node_to_follow = new_node_to_follow
	_update_target_position()


func _update_target_position() -> void:
	if node_to_follow:
		_target_position = node_to_follow.global_position


func _physics_process(_delta: float) -> void:
	character.velocity = (character.global_position.direction_to(_target_position) * walk_speed)
	character.move_and_slide()

	if not is_zero_approx(character.velocity.x):
		character.look_at_side = (
			Enums.LookAtSide.LEFT if character.velocity.x < 0 else Enums.LookAtSide.RIGHT
		)

	if character.global_position.is_equal_approx(_target_position):
		target_reached.emit()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENABLED:
			_update_target_position()
		NOTIFICATION_DISABLED:
			pass
