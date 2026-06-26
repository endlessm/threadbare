extends CharacterBody2D

@export var speed: float = 50.0
@export var navigation_update_interval: float = 0.2

@export var health: int = 2
@export var damage: int = 10
@export var attack_cooldown: float = 1.0
@export var attack_range: float = 60.0
@export var repel_force: float = 300.0
@export var repel_stun_time: float = 0.5

## Margen de seguridad para no acercarse a los bordes del área
@export var wander_margin: float = 40.0

@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
@onready var timer: Timer = $Timer
@onready var attack_timer: Timer = $AttackTimer
@onready var repel_timer: Timer = $RepelTimer
@onready var sprite: Sprite2D = $zombie

var player: Player = null
var can_attack: bool = true
var is_repelled: bool = false

# Datos del área (asignados por el spawner)
var spawn_center: Vector2 = Vector2.ZERO
var spawn_half_size: Vector2 = Vector2(400, 300)
var is_chasing: bool = false

# Vagabundeo simple
var wander_target: Vector2 = Vector2.ZERO
var wander_valid: bool = false

# Detección de atasco
var stuck_timer: float = 0.0
const STUCK_TIME_THRESHOLD: float = 1.0
const STUCK_SPEED_THRESHOLD: float = 5.0


func _ready():
	buscar_jugador_seguro()
	add_to_group("enemies")

	collision_layer = 2
	collision_mask = 1

	if not timer:
		timer = Timer.new()
		timer.wait_time = navigation_update_interval
		timer.one_shot = false
		add_child(timer)
	timer.timeout.connect(_on_timer_timeout)
	timer.start()

	if not attack_timer:
		attack_timer = Timer.new()
		attack_timer.one_shot = true
		add_child(attack_timer)
	else:
		attack_timer.one_shot = true
	if attack_timer.timeout.is_connected(_on_attack_cooldown_end):
		attack_timer.timeout.disconnect(_on_attack_cooldown_end)
	attack_timer.timeout.connect(_on_attack_cooldown_end)

	if not repel_timer:
		repel_timer = Timer.new()
		repel_timer.one_shot = true
		add_child(repel_timer)
	repel_timer.timeout.connect(_on_repel_end)

	# Iniciar vagabundeo
	iniciar_vagabundeo_simple()


func buscar_jugador_seguro():
	for nodo in get_tree().get_nodes_in_group("player"):
		if nodo is Player:
			player = nodo
			return
	for nodo in get_tree().root.get_children():
		if nodo is Player:
			player = nodo
			return
		for hijo in nodo.get_children():
			if hijo is Player:
				player = hijo
				return


func _physics_process(delta):
	if not player or not is_instance_valid(player):
		buscar_jugador_seguro()
		return

	if is_repelled:
		move_and_slide()
		$zombie.global_position = global_position
		return

	var dentro_del_area = _jugador_en_area()

	if dentro_del_area and not is_chasing:
		is_chasing = true
		actualizar_objetivo_navegacion()
	elif not dentro_del_area and is_chasing:
		is_chasing = false
		iniciar_vagabundeo_simple()

	if is_chasing and can_attack and global_position.distance_to(player.global_position) < attack_range:
		_deal_damage_to_player()

	if is_chasing:
		_perseguir_con_navegacion()
	else:
		_vagabundear_recto(delta)


func _perseguir_con_navegacion():
	if navigation_agent_2d.is_target_reachable():
		var next_point = navigation_agent_2d.get_next_path_position()
		var direction = global_position.direction_to(next_point)
		velocity = direction * speed
	else:
		var direction = global_position.direction_to(player.global_position)
		velocity = direction * speed

	move_and_slide()
	$zombie.global_position = global_position
	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0


func _vagabundear_recto(delta: float):
	# Si no hay destino o llegó, generar uno nuevo
	if not wander_valid or global_position.distance_to(wander_target) < 10.0:
		iniciar_vagabundeo_simple()
		if not wander_valid:
			velocity = Vector2.ZERO
			return

	var direction = global_position.direction_to(wander_target)
	velocity = direction * speed
	move_and_slide()
	$zombie.global_position = global_position
	if direction.x != 0:
		sprite.flip_h = direction.x < 0

	# Detectar atasco contra paredes
	if velocity.length() < STUCK_SPEED_THRESHOLD:
		stuck_timer += delta
		if stuck_timer > STUCK_TIME_THRESHOLD:
			iniciar_vagabundeo_simple()
			stuck_timer = 0.0
			return
	else:
		stuck_timer = 0.0

	# Si por un empuje salió del área, simplemente recalcular destino dentro
	if not _punto_en_area(global_position):
		iniciar_vagabundeo_simple()


func _jugador_en_area() -> bool:
	if not player:
		return false
	return _punto_en_area(player.global_position)


func actualizar_objetivo_navegacion():
	if player:
		navigation_agent_2d.target_position = player.global_position


func iniciar_vagabundeo_simple():
	# Límites interiores con margen para no pegarse a los bordes
	var min_x = spawn_center.x - spawn_half_size.x + wander_margin
	var max_x = spawn_center.x + spawn_half_size.x - wander_margin
	var min_y = spawn_center.y - spawn_half_size.y + wander_margin
	var max_y = spawn_center.y + spawn_half_size.y - wander_margin

	# Si el margen hace que el área se vuelva negativa, usar el centro
	if min_x >= max_x:
		min_x = spawn_center.x
		max_x = spawn_center.x
	if min_y >= max_y:
		min_y = spawn_center.y
		max_y = spawn_center.y

	var rand_x = randf_range(min_x, max_x)
	var rand_y = randf_range(min_y, max_y)
	wander_target = Vector2(rand_x, rand_y)
	wander_valid = true


func _punto_en_area(punto: Vector2) -> bool:
	return (
		punto.x >= spawn_center.x - spawn_half_size.x and
		punto.x <= spawn_center.x + spawn_half_size.x and
		punto.y >= spawn_center.y - spawn_half_size.y and
		punto.y <= spawn_center.y + spawn_half_size.y
	)


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
	if _jugador_en_area():
		is_chasing = true
		actualizar_objetivo_navegacion()
	else:
		is_chasing = false
		iniciar_vagabundeo_simple()


func _on_timer_timeout():
	if not is_chasing:
		if not wander_valid or global_position.distance_to(wander_target) < 10.0:
			iniciar_vagabundeo_simple()
	else:
		if player and is_instance_valid(player):
			actualizar_objetivo_navegacion()
