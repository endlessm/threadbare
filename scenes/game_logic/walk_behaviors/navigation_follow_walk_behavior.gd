# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name NavigationFollowWalkBehavior
extends BaseCharacterBehavior
## @experimental
##
## Make the character follow a target, using a [NavigationAgent2D] to
## route towards it.

## Emitted when the character starts or stops running.
signal running_changed(is_running: bool)

## Emitted when [member target] becomes reached or not.
signal target_reached_changed(is_reached: bool)

## Emitted when [member is_target_reachable] changes.
signal target_unreachable_changed(is_reachable: bool)

## Parameters controlling the speed at which this character walks. If unset, the default values of
## [CharacterSpeeds] are used.
@export var speeds: CharacterSpeeds

## The target to follow.
@export var target: Node2D:
	set = _set_target

## The [NavigationAgent2D] to use to navigate to [member target]
@export var agent: NavigationAgent2D:
	set = _set_agent

## The distance to travel between retargetting.
## If zero, it will constantly retarget.
@export_range(0, 100, 1, "or_greater", "suffix:px") var travel_distance: float = 50.0

## The distance to [member target] above which this character will start running.
## If this is 0, this character will always move at [member CharacterSpeeds.run_speed];
## if this is [const INF], this character will always move at [member CharacterSpeeds.walk_speed].
@export_range(0, 640, 32, "or_greater", "suffix:px") var running_distance: float = 196.0

## The current distance travelled since last direction update.
var distance: float = 0

## True if the character is running
var is_running: bool:
	set = _set_is_running

## True if the character has reached [member target].
var is_target_reached: bool:
	set = _set_is_target_reached

## True if navigation has finished and [member target] is unreachable.
var is_target_unreachable: bool:
	set = _set_is_target_unreachable


func _set_target(new_target: Node2D) -> void:
	target = new_target
	update_configuration_warnings()


func _set_agent(new_agent: NavigationAgent2D) -> void:
	if agent:
		agent.target_reached.disconnect(_on_agent_target_reached)
		agent.navigation_finished.disconnect(_on_agent_navigation_finished)
	agent = new_agent
	if agent:
		agent.target_reached.connect(_on_agent_target_reached)
		agent.navigation_finished.connect(_on_agent_navigation_finished)
	update_configuration_warnings()


func _set_is_running(new_is_running: bool) -> void:
	if is_running == new_is_running:
		return
	is_running = new_is_running
	running_changed.emit(is_running)


func _set_is_target_reached(new_is_target_reached: bool) -> void:
	if is_target_reached == new_is_target_reached:
		return
	is_target_reached = new_is_target_reached
	target_reached_changed.emit(is_target_reached)


func _set_is_target_unreachable(new_is_target_unreachable: bool) -> void:
	if is_target_unreachable == new_is_target_unreachable:
		return
	is_target_unreachable = new_is_target_unreachable
	target_unreachable_changed.emit(is_target_unreachable)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := super._get_configuration_warnings()
	if not target:
		warnings.append("Target property must be set.")
	if not agent:
		warnings.append("Agent property must be set.")
	return warnings


func _update_target_position() -> void:
	if agent and target:
		agent.target_position = target.global_position


func _on_agent_target_reached() -> void:
	is_target_reached = true
	is_target_unreachable = false


func _on_agent_navigation_finished() -> void:
	if agent.is_target_reachable():
		# The NavigationAgent2D documentation specifies that target_reached will
		# be emitted just before navigation_finished when the target is
		# reachable.
		assert(is_target_reached)
	else:
		is_target_reached = false
		is_target_unreachable = true


func _ready() -> void:
	if Engine.is_editor_hint():
		set_physics_process(false)
		return

	if not speeds:
		speeds = CharacterSpeeds.new()

	_update_target_position()


func _physics_process(delta: float) -> void:
	var retarget := false

	if agent.is_navigation_finished():
		character.velocity = character.velocity.move_toward(
			Vector2.ZERO, speeds.stopping_step * delta
		)
		# Retarget if the target has moved more than some threshold
		# TODO: should this be a separate threshold?
		retarget = agent.target_position.distance_to(target.global_position) > travel_distance
	else:
		is_target_reached = false

		var next_path_position := agent.get_next_path_position()
		var direction := global_position.direction_to(next_path_position)
		is_running = agent.distance_to_target() > running_distance
		var speed := speeds.run_speed if is_running else speeds.walk_speed
		character.velocity = character.velocity.move_toward(
			direction * speed, speeds.moving_step * delta
		)

	character.move_and_slide()
	distance += character.get_position_delta().length()

	if retarget or distance > travel_distance:
		_update_target_position()
		distance = 0.0
