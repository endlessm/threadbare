extends Node2D

@export var enemy_scene: PackedScene
@export var player_target: Node2D
@export_range(0.0, 60.0, 0.5) var spawn_delay: float = 0.0

func _ready() -> void:
	pass

func activate_rift() -> void:
	if spawn_delay > 0.0:
		await get_tree().create_timer(spawn_delay).timeout
	_spawn_enemy()

func _spawn_enemy() -> void:
	if not is_instance_valid(enemy_scene): 
		return
		
	var enemy: Node = enemy_scene.instantiate()
	
	if "player_target" in enemy:
		enemy.player_target = player_target
	
	get_parent().call_deferred("add_child", enemy)
	enemy.global_position = global_position
	
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)

func _on_enemy_died() -> void:
	queue_free()
