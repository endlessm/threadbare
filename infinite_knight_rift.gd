extends Node2D

@export var enemy_scene: PackedScene
@export var player_target: Node2D # Aqui arrastraremos al jugador
@export_range(0.0, 60.0, 0.5) var spawn_delay: float = 0.0

func _ready() -> void:
	pass

func activate_rift() -> void:
	print("¡Una grieta escuchó la orden de despertar!")
	if spawn_delay > 0.0:
		await get_tree().create_timer(spawn_delay).timeout
	_spawn_enemy()

func _spawn_enemy() -> void:
	if not is_instance_valid(enemy_scene): return
		
	var enemy: Node = enemy_scene.instantiate()
	
	# La grieta le pasa la ubicación del jugador al enemigo antes de soltarlo
	enemy.player_target = player_target
	
	get_parent().call_deferred("add_child", enemy)
	enemy.global_position = global_position
	
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)

func _on_enemy_died() -> void:
	queue_free()
