@tool
class_name Teleporter
extends Area2D

const SPAWN_POINT_GROUP_NAME: String = "spawn_point"

@export_file("*.tscn") var scene_to_go_to: String:
	set(new_value):
		scene_to_go_to = new_value
		_update_available_spawn_points()
		notify_property_list_changed()

var spawn_point_path: NodePath:
	set(new_val):
		if new_val == ^"NONE":
			spawn_point_path = ^""
		else:
			spawn_point_path = new_val

var _available_spawn_points: Array[NodePath] = []


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(3, true)
	set_collision_mask_value(1, true)

	if Engine.is_editor_hint():
		return

	self.body_entered.connect(_on_body_entered)


func _on_body_entered(_body: PhysicsBody2D) -> void:
	if scene_to_go_to:
		# We are using call_deferred here because removing nodes with
		# collisions during a callback caused by a collision might cause
		# undesired behavior.
		SceneSwitcher.change_scene_to.call_deferred(scene_to_go_to, spawn_point_path)


func _update_available_spawn_points() -> void:
	if ResourceLoader.exists(scene_to_go_to, "PackedScene"):
		var packed_scene: PackedScene = load(scene_to_go_to)
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

	return property_list
