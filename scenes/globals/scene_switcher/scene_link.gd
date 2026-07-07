# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name SceneLink
extends Node2D
## Represents a potential transition to another scene.
##
## This can be used directly, but acts primarily a base class for other
## components: [Cinematic], [CollectibleItem], and the Teleporter scene.

const SPAWN_POINT_GROUP_NAME: String = "spawn_point"

## Scene to switch to when the player enters this teleport. If empty, the player
## will teleport within the current scene, to the position specified by [member
## spawn_point_path].
@export_file("*.tscn") var next_scene: String:
	set(new_value):
		next_scene = new_value
		_update_available_spawn_points()

@export_tool_button("Open Next Scene") var open_next_scene: Callable = _open_next_scene

## Which SpawnPoint in [member next_scene] the player character should start at;
## or blank/NONE to start at the default position in the scene.
@export var spawn_point_path: NodePath:
	set(new_val):
		if new_val == ^"NONE":
			spawn_point_path = ^""
		else:
			spawn_point_path = new_val
		update_configuration_warnings()

@export_group("Transition")

## Whether to use a visual transition effect when switching to the target scene.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var use_transition: bool = true:
	set(new_val):
		use_transition = new_val
		notify_property_list_changed()

## Transition to use at the start of the switch to [member next_scene].
@export var enter_transition: Transition.Effect = Transition.Effect.FADE

## Transition to use at the end of the switch to [member next_scene].
@export var exit_transition: Transition.Effect = Transition.Effect.FADE

var _available_spawn_points: Array[NodePath] = []


func _ready() -> void:
	if Engine.is_editor_hint():
		_update_available_spawn_points()
		return


## Trigger the scene-switch or teleport described by [member next_scene] and
## [member spawn_point_path], with the configured transition.
func switch() -> void:
	var next_scene_path := _get_next_scene_path()
	if next_scene_path and next_scene_path != get_tree().current_scene.scene_file_path:
		if use_transition:
			SceneSwitcher.change_to_file_with_transition(
				next_scene, spawn_point_path, enter_transition, exit_transition
			)
		else:
			SceneSwitcher.change_to_file(next_scene, spawn_point_path)
	else:
		var spawn_point: SpawnPoint = get_node_or_null(spawn_point_path)

		if is_instance_valid(spawn_point):
			if use_transition:
				await Transitions.do_transition(
					self._teleport_to_spawn_point.bind(spawn_point),
					enter_transition,
					exit_transition
				)
			else:
				self._teleport_to_spawn_point(spawn_point)


func _teleport_to_spawn_point(spawn_point: SpawnPoint) -> void:
	spawn_point.move_player_to_self_position(true)


func _get_next_scene_path() -> String:
	return ResourceUID.ensure_path(next_scene) if next_scene else ""


func _open_next_scene() -> void:
	var editor_interface := Engine.get_singleton("EditorInterface")
	var next_scene_path: String = _get_next_scene_path()
	if (
		editor_interface
		and next_scene_path
		and next_scene_path != get_tree().edited_scene_root.scene_file_path
	):
		editor_interface.open_scene_from_path.call_deferred(next_scene_path)


func _update_available_spawn_points() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return

	var next_scene_path: String = _get_next_scene_path()
	if not next_scene_path or next_scene_path == get_tree().edited_scene_root.scene_file_path:
		var spawn_points := get_tree().get_nodes_in_group("spawn_point")
		_available_spawn_points.assign(
			spawn_points.map(func(spawn_point: Node) -> String: return get_path_to(spawn_point))
		)
	elif ResourceLoader.exists(next_scene, "PackedScene"):
		var packed_scene: PackedScene = load(next_scene)
		var paths: Array[NodePath] = []
		var scene_state: SceneState = packed_scene.get_state()

		for i: int in scene_state.get_node_count():
			var path := scene_state.get_node_path(i)
			var node_groups := scene_state.get_node_groups(i)
			var instance := scene_state.get_node_instance(i)
			if instance:
				node_groups.append_array(instance.get_state().get_node_groups(0))
			if SPAWN_POINT_GROUP_NAME in node_groups:
				var node_path_as_string := String(path)

				paths.push_back(NodePath(node_path_as_string.replace("./", "")))

		_available_spawn_points = paths

	notify_property_list_changed()
	update_configuration_warnings()


func _validate_property(property: Dictionary) -> void:
	match property.name:
		"open_next_scene":
			var next_scene_path: String = _get_next_scene_path()
			var edited_scene_root := get_tree().edited_scene_root if is_inside_tree() else null
			if (
				not next_scene_path
				or (edited_scene_root and next_scene_path == edited_scene_root.scene_file_path)
			):
				property.usage |= PROPERTY_USAGE_READ_ONLY

		"spawn_point_path":
			property.type = TYPE_STRING
			property.hint = PROPERTY_HINT_ENUM
			property.hint_string = ",".join(["NONE"] + _available_spawn_points)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray
	if spawn_point_path and spawn_point_path not in _available_spawn_points:
		warnings.append("Spawn point '%s' does not exist" % [spawn_point_path])
	return warnings
