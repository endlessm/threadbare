extends Node2D

@export var zombie_scene: PackedScene
@export var spawn_interval: float = 5.0
@export var spawn_area_half_size: Vector2 = Vector2(400, 300)

var spawn_timer: Timer

func _ready():
	spawn_timer = $Timer
	if not spawn_timer:
		spawn_timer = Timer.new()
		add_child(spawn_timer)
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()

func _on_spawn_timer_timeout():
	if not zombie_scene:
		print("Error: zombie_scene no asignado")
		return
	var new_zombie = zombie_scene.instantiate()
	var random_offset = Vector2(
		randf_range(-spawn_area_half_size.x, spawn_area_half_size.x),
		randf_range(-spawn_area_half_size.y, spawn_area_half_size.y)
	)
	new_zombie.global_position = global_position + random_offset
	get_parent().add_child(new_zombie)
