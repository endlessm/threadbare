extends CharacterBody2D

@export var speed: float = 120.0
@export var detection_range: float = 800.0  # rango aumentado

var player: Node2D

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	if not player:
		push_warning("No se encontró el jugador.")

func _physics_process(delta: float) -> void:
	if player and is_instance_valid(player):
		var distance: float = global_position.distance_to(player.global_position)
		
		if distance <= detection_range:
			var direction: Vector2 = (player.global_position - global_position).normalized()
			velocity = direction * speed
		else:
			velocity = Vector2.ZERO
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()
