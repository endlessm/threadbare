extends CharacterBody2D

@export var speed: float = 50.0
@export var health: int = 2
@export var damage: int = 1
@export var attack_cooldown: float = 1.0
@export var repel_force: float = 300.0
@export var repel_stun_time: float = 0.5

var target: Player = null
var can_attack: bool = true
var is_repelled: bool = false

@onready var sprite: Sprite2D = $zombie
@onready var attack_timer: Timer = $AttackTimer
@onready var repel_timer: Timer = $RepelTimer

func _ready():
	add_to_group("enemies")
	buscar_jugador()

	if not attack_timer:
		attack_timer = Timer.new(); attack_timer.one_shot = true; add_child(attack_timer)
	else: attack_timer.one_shot = true
	if attack_timer.timeout.is_connected(_on_attack_cooldown_end): attack_timer.timeout.disconnect(_on_attack_cooldown_end)
	attack_timer.timeout.connect(_on_attack_cooldown_end)

	if not repel_timer:
		repel_timer = Timer.new(); repel_timer.one_shot = true; add_child(repel_timer)
	repel_timer.timeout.connect(_on_repel_end)

	# Activar el dibujo de depuración
	set_process(true)

func buscar_jugador():
	for nodo in get_tree().root.get_children():
		if nodo is Player:
			target = nodo
			return
		for hijo in nodo.get_children():
			if hijo is Player:
				target = hijo
				return

func _physics_process(_delta):
	if not target:
		buscar_jugador()
		return

	if is_repelled:
		move_and_slide()
		$zombie.global_position = global_position   # Forzar sprite
		return

	var dir_to_player = (target.global_position - global_position).normalized()
	velocity = dir_to_player * speed
	move_and_slide()

	# Alinear visual y lógica
	$zombie.global_position = global_position

	if dir_to_player.x != 0:
		sprite.flip_h = dir_to_player.x < 0

	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		if col.get_collider() == target and can_attack:
			_deal_damage_to_player()
			velocity = -velocity * 0.5
			break

func _deal_damage_to_player():
	if target and target.has_method("take_damage"):
		target.take_damage(damage)
		can_attack = false
		attack_timer.start(attack_cooldown)

func _on_attack_cooldown_end(): can_attack = true

func take_damage(amount: int):
	health -= amount
	print("Zombie recibe daño. Vida restante:", health)
	if health <= 0: queue_free()

func got_repelled(direction: Vector2):
	if is_repelled: return
	is_repelled = true
	can_attack = false
	velocity = direction * repel_force
	repel_timer.start(repel_stun_time)

func _on_repel_end():
	is_repelled = false
	can_attack = true
	velocity = Vector2.ZERO

func _draw():
	draw_circle(Vector2.ZERO, 10, Color.RED)
