extends Node

@export var damage: int = 1
@export var attack_cooldown: float = 0.5
@export var attack_range: float = 80.0   # Distancia de golpe

var can_attack: bool = true

func _ready():
	# Asegura que el nodo está en el árbol del jugador
	pass

func _input(event):
	if event.is_action_pressed("attack") and can_attack:
		attack()

func attack():
	can_attack = false
	
	# Obtener la posición del jugador (propietario de este nodo)
	var player_pos = owner.global_position
	
	# Buscar todos los enemigos en el grupo "enemies"
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.has_method("take_damage"):
			var dist = player_pos.distance_to(enemy.global_position)
			if dist <= attack_range:
				enemy.take_damage(damage)
				print("Golpe a ", enemy.name)
	
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
