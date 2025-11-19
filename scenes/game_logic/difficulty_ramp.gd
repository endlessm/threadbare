extends Node

@export var speed_multiplier: float = 1.5

func _ready() -> void:
	# Wait for the level to fully load
	await get_tree().process_frame
	
	var barrels: Array[Node] = get_tree().get_nodes_in_group("filling_barrels")
	
	for barrel: Node in barrels:
		if barrel is FillingBarrel:
			barrel.completed.connect(_on_barrel_completed)

func _on_barrel_completed() -> void:
	_increase_enemies_speed()

func _increase_enemies_speed() -> void:
	var enemies: Array[Node] = get_tree().get_nodes_in_group("throwing_enemy")
	
	for enemy_node: Node in enemies:
		if is_instance_valid(enemy_node) and enemy_node is ThrowingEnemy:
			var enemy: ThrowingEnemy = enemy_node as ThrowingEnemy
			
			# Decrease the period to make them shoot faster
			enemy.throwing_period = enemy.throwing_period / speed_multiplier
			
			# Update the timer immediately if it's currently running
			if enemy.timer and not enemy.timer.is_stopped():
				enemy.timer.wait_time = enemy.throwing_period
