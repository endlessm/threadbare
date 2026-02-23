class_name SpawnerBroken
extends Marker2D
## @experimental
## Periodically spawns a scene at this node's position.
##
## This could be used, for example, to have a new enemy appear every few seconds.
## This class is marked experimental because it seems to be buggy.

## Number of seconds to wait between spawning [member scene_to_spawn].
@export_range(1.0, 600.0, 1.0, "suffix:s", "or_greater") var spawn_interval := 5.0

## Scene to spawn every [member spawn_interval] seconds.
@export var scene_to_spawn: PackedScene


func _ready() -> void:
	var timer := Timer.new()
	add_child(timer)

	timer.timeout.connect(spawn)

	# Convert seconds to milliseconds for timer.start() method.
	# FIXME: Is this correct?? It seems to spawn too fast!
	timer.start(spawn_interval / 1000)


## Spawns an instance of [member scene_to_spawn] at the same position as this node, as a sibling.
func spawn() -> void:
	var scene := scene_to_spawn.instantiate()
	scene.global_position = global_position
	get_parent().add_child(scene)
