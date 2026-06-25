@tool
extends Node2D

@export var zombie_scene: PackedScene
@export var spawn_interval: float = 5.0
@export var spawn_area_half_size: Vector2 = Vector2(400, 300):
	set(val):
		spawn_area_half_size = val
		queue_redraw()
@export var max_zombies: int = 10

var spawn_timer: Timer
var total_spawned: int = 0   # <-- Contador de zombis generados (nunca baja)


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	spawn_timer = $Timer
	if not spawn_timer:
		spawn_timer = Timer.new()
		add_child(spawn_timer)
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var rect: Rect2 = Rect2(-spawn_area_half_size, spawn_area_half_size * 2)
	draw_rect(rect, Color(1, 0, 0, 0.1), true)   # relleno suave
	draw_rect(rect, Color(1, 0, 0, 0.4), false, 2.0) # borde visible


func _on_spawn_timer_timeout() -> void:
	if not zombie_scene:
		return
	# Detener si ya alcanzamos el total máximo
	if total_spawned >= max_zombies:
		return
	var new_zombie: Node2D = zombie_scene.instantiate()
	var random_offset: Vector2 = Vector2(
		randf_range(-spawn_area_half_size.x, spawn_area_half_size.x),
		randf_range(-spawn_area_half_size.y, spawn_area_half_size.y)
	)
	new_zombie.global_position = global_position + random_offset
	get_parent().add_child(new_zombie)
	total_spawned += 1   # Incrementar el contador (jamás se reduce)
