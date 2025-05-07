# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name Teleporter
extends Area2D

const SPAWN_POINT_GROUP_NAME: String = "spawn_point"

@export_file("*.tscn") var next_scene: String:
	set(new_value):
		next_scene = new_value
		_update_available_spawn_points()
		notify_property_list_changed()

@export var use_transition: bool = true:
	set(new_val):
		use_transition = new_val
		notify_property_list_changed()

var spawn_point_path: NodePath:
	set(new_val):
		if new_val == ^"NONE":
			spawn_point_path = ^""
		else:
			spawn_point_path = new_val

var enter_transition: Transition.Effect = Transition.Effect.LEFT_TO_RIGHT_WIPE
var exit_transition: Transition.Effect = Transition.Effect.RIGHT_TO_LEFT_WIPE

var _available_spawn_points: Array[NodePath] = []


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(3, true)
	set_collision_mask_value(1, true)

	if Engine.is_editor_hint():
		_update_available_spawn_points()
		notify_property_list_changed()
		return

	self.body_entered.connect(_on_body_entered, CONNECT_ONE_SHOT)


func _on_body_entered(_body: PhysicsBody2D) -> void:
	if next_scene and next_scene != get_tree().current_scene.scene_file_path:
		# We are using call_deferred here because removing nodes with
		# collisions during a callback caused by a collision might cause
		# undesired behavior.
		if use_transition:
			SceneSwitcher.change_to_file_with_transition.call_deferred(
				next_scene, spawn_point_path, enter_transition, exit_transition
			)
		else:
			SceneSwitcher.change_to_file(next_scene, spawn_point_path)
	else:
		var spawn_point: SpawnPoint = get_node_or_null(spawn_point_path)

		if is_instance_valid(spawn_point):
			if use_transition:
				Transitions.do_transition(
					self._teleport_to_spawn_point.bind(spawn_point),
					enter_transition,
					exit_transition
				)
			else:
				self._teleport_to_spawn_point(spawn_point)


func _teleport_to_spawn_point(spawn_point: SpawnPoint) -> void:
	spawn_point.move_player_to_self_position(true)
	self.body_entered.connect(_on_body_entered, CONNECT_ONE_SHOT)


func _get_next_scene_path() -> String:
	if next_scene.begins_with("uid"):
		return ResourceUID.get_id_path(ResourceUID.text_to_id(next_scene))

	return next_scene


func _update_available_spawn_points() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return

	var next_scene_path: String = _get_next_scene_path()

	if not next_scene or next_scene_path == get_tree().edited_scene_root.scene_file_path:
		var spawn_points := get_tree().get_nodes_in_group("spawn_point")
		_available_spawn_points.assign(
			spawn_points.map(func(spawn_point: Node) -> String: return get_path_to(spawn_point))
		)

	elif ResourceLoader.exists(next_scene, "PackedScene"):
		var packed_scene: PackedScene = load(next_scene)
		var paths: Array[NodePath] = []
		var scene_state: SceneState = packed_scene.get_state()

		for i: int in scene_state.get_node_count():
			if SPAWN_POINT_GROUP_NAME in scene_state.get_node_groups(i):
				var node_path_as_string: String = String(scene_state.get_node_path(i))

				paths.push_back(NodePath(node_path_as_string.replace("./", "")))

		_available_spawn_points = paths


func _get_property_list() -> Array[Dictionary]:
	var property_list: Array[Dictionary] = []

	property_list.push_back(
		{
			"name": "spawn_point_path",
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": ",".join(["NONE"] + _available_spawn_points),
			"usage": PROPERTY_USAGE_DEFAULT
		}
	)

	if use_transition:
		property_list.push_back(
			PropertyUtils.enum_property("exit_transition", &"Transition.Effect", Transition.Effect)
		)
		property_list.push_back(
			PropertyUtils.enum_property("enter_transition", &"Transition.Effect", Transition.Effect)
		)

	return property_list
