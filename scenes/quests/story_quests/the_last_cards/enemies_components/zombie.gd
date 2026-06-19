extends CharacterBody2D

@export var speed: float = 50.0
@export var navigation_update_interval: float = 0.2

## Salud del zombi
@export var health: int = 2
## Daño que inflige al jugador
@export var damage: int = 1
## Tiempo de espera entre ataques (segundos)
@export var attack_cooldown: float = 1.0
## Distancia a la que el zombi empieza a atacar al jugador
@export var attack_range: float = 60.0

## Fuerza de repulsión al ser repelido
@export var repel_force: float = 300.0
## Tiempo de aturdimiento tras la repulsión
@export var repel_stun_time: float = 0.5

@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
@onready var timer: Timer = $Timer
@onready var attack_timer: Timer = $AttackTimer
@onready var repel_timer: Timer = $RepelTimer
@onready var sprite: Sprite2D = $zombie

var player: Player = null
var can_attack: bool = true
var is_repelled: bool = false

func _ready():
	buscar_jugador_seguro()
	add_to_group("enemies")

	# Capas de colisión: solo choca con el escenario
	collision_layer = 2
	collision_mask = 1

	# Configurar timer de actualización de ruta
	if not timer:
		timer = Timer.new()
		timer.wait_time = navigation_update_interval
		timer.one_shot = false
		add_child(timer)
	timer.timeout.connect(_on_timer_timeout)
	timer.start()

	# Configurar timer de ataque
	if not attack_timer:
		attack_timer = Timer.new()
		attack_timer.one_shot = true
		add_child(attack_timer)
	else:
		attack_timer.one_shot = true
	if attack_timer.timeout.is_connected(_on_attack_cooldown_end):
		attack_timer.timeout.disconnect(_on_attack_cooldown_end)
	attack_timer.timeout.connect(_on_attack_cooldown_end)

	# Configurar timer de repulsión
	if not repel_timer:
		repel_timer = Timer.new()
		repel_timer.one_shot = true
		add_child(repel_timer)
	repel_timer.timeout.connect(_on_repel_end)

	# Primer objetivo de navegación
	if player:
		navigation_agent_2d.target_position = player.global_position

func buscar_jugador_seguro():
	# Buscar el primer nodo de clase Player en el grupo "player" (ignora otros)
	for nodo in get_tree().get_nodes_in_group("player"):
		if nodo is Player:
			player = nodo
			return
	# Si no encuentra, busca por clase sin grupo
	for nodo in get_tree().root.get_children():
		if nodo is Player:
			player = nodo
			return
		for hijo in nodo.get_children():
			if hijo is Player:
				player = hijo
				return

func _physics_process(_delta):
	if not player or not is_instance_valid(player):
		buscar_jugador_seguro()
		return

	# Si está repelido, solo moverse con la inercia del empuje
	if is_repelled:
		move_and_slide()
		$zombie.global_position = global_position
		return

	# Comprobar si puede atacar al jugador por proximidad
	if can_attack and global_position.distance_to(player.global_position) < attack_range:
		_deal_damage_to_player()

	# Moverse siempre hacia el siguiente punto del camino
	var next_point = navigation_agent_2d.get_next_path_position()
	var direction = global_position.direction_to(next_point)
	velocity = direction * speed
	move_and_slide()

	# Sincronizar visual del sprite
	$zombie.global_position = global_position
	if direction.x != 0:
		sprite.flip_h = direction.x < 0

func _deal_damage_to_player():
	print("Zombi atacando al jugador ", player.name)
	if player.has_method("take_damage"):
		player.take_damage(damage)
	can_attack = false
	attack_timer.start(attack_cooldown)

func _on_attack_cooldown_end():
	can_attack = true

func take_damage(amount: int):
	health -= amount
	print("Zombie recibe daño. Vida restante:", health)
	if health <= 0:
		queue_free()

func got_repelled(direction: Vector2):
	if is_repelled:
		return
	is_repelled = true
	can_attack = false
	velocity = direction * repel_force
	repel_timer.start(repel_stun_time)

func _on_repel_end():
	is_repelled = false
	can_attack = true
	velocity = Vector2.ZERO

func _on_timer_timeout():
	if player and is_instance_valid(player):
		navigation_agent_2d.target_position = player.global_position
