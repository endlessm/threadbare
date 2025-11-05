extends Area2D
class_name FireBoss

@export var max_health: int = 400
@export var fireball_scene: PackedScene
@export var projectile_speed: float = 250.0
@export var melee_damage: int = 15

var current_health: int
var player: Node2D
var shoot_timer: Timer
var phase: int = 1
var fire_rate: float = 2.5
var enraged: bool = false

func _ready() -> void:
	current_health = max_health
	add_to_group("throwing_enemy")

	player = get_tree().get_first_node_in_group("player")
	if player:
		player.mode = player.Mode.FIGHTING
		print("🔥 Jugador en modo FIGHTING (por FireBoss)")

	body_entered.connect(_on_body_entered)

	# Timer de disparo
	shoot_timer = Timer.new()
	shoot_timer.wait_time = fire_rate
	shoot_timer.autostart = true
	shoot_timer.timeout.connect(_shoot_pattern)
	add_child(shoot_timer)

	if has_node("Label"):
		$Label.text = str(current_health)
		$Label.position = Vector2(0, -80)

	print("👹 FireBoss listo con", max_health, "HP")

func _process(_delta: float) -> void:
	_update_phase()
	if player and is_instance_valid(player):
		look_at(player.global_position)

# =====================
#   SISTEMA DE FASES
# =====================

func _update_phase() -> void:
	var ratio = float(current_health) / max_health

	match phase:
		1:
			if ratio <= 0.75:
				_enter_phase(2)
		2:
			if ratio <= 0.5:
				_enter_phase(3)
		3:
			if ratio <= 0.25:
				_enter_phase(4)

func _enter_phase(new_phase: int) -> void:
	if new_phase <= phase:
		return

	phase = new_phase
	print("🔥🔥 Entrando a Fase", phase)

	match phase:
		2:
			fire_rate = 1.8
			projectile_speed = 300.0
			$Label.modulate = Color.ORANGE_RED
			_spawn_explosion()
			_add_shield()
		3:
			fire_rate = 1.2
			projectile_speed = 350.0
			$Label.modulate = Color.DARK_RED
			_spawn_explosion()
			_multi_shot_attack()
		4:
			fire_rate = 0.8
			projectile_speed = 400.0
			enraged = true
			$Label.modulate = Color.CRIMSON
			_spawn_explosion()
			_add_shield()
			_multi_shot_attack()
			print("💀 Fase final: Enfurecido, ataques dobles!")

	# Reinicia temporizador para reflejar nueva velocidad
	shoot_timer.wait_time = fire_rate

# =====================
#   ATAQUES
# =====================

func _shoot_pattern() -> void:
	if not fireball_scene or not player or not is_instance_valid(player):
		return

	match phase:
		1:
			_shoot_fireball(player.global_position)
		2:
			_shoot_burst(3, 10)
		3:
			_spiral_shot(8)
		4:
			_spiral_shot(12)
			if enraged:
				await get_tree().create_timer(0.4).timeout
				_multi_shot_attack()

func _shoot_fireball(target_pos: Vector2) -> void:
	var fireball: Fireball = fireball_scene.instantiate()
	get_parent().add_child(fireball)
	fireball.global_position = global_position
	fireball.shoot_toward(target_pos)
	fireball.speed = projectile_speed
	fireball.can_be_parried = true
	print("🔥 FireBoss disparó fireball hacia el jugador")

func _shoot_burst(count: int, spread: float) -> void:
	for i in count:
		var offset = randf_range(-spread, spread)
		var dir = (player.global_position - global_position).rotated(deg_to_rad(offset))
		_shoot_fireball(global_position + dir * 10)
	await get_tree().create_timer(0.3).timeout

func _spiral_shot(bullets: int) -> void:
	for i in bullets:
		var angle = TAU * i / bullets + randf_range(-0.2, 0.2)
		var dir = Vector2.RIGHT.rotated(angle)
		var fireball: Fireball = fireball_scene.instantiate()
		get_parent().add_child(fireball)
		fireball.global_position = global_position
		fireball.shoot_toward(global_position + dir * 100)
		fireball.speed = projectile_speed
		fireball.can_be_parried = true
	print("🔥 Disparo en espiral (", bullets, "balas)")


func _multi_shot_attack() -> void:
	for i in range(3):
		await get_tree().create_timer(0.4).timeout
		_shoot_burst(4, 25)

# =====================
#   EFECTOS Y ESCUDOS
# =====================

func _spawn_explosion() -> void:
	if has_node("Explosion"):
		$Explosion.restart()
	else:
		var particles = GPUParticles2D.new()
		add_child(particles)
		particles.amount = 80
		particles.lifetime = 1.0
		particles.emitting = true
		particles.scale = Vector2(1.5, 1.5)

		# 🔹 Material de partículas (válido para GPUParticles2D)
		var mat = ParticleProcessMaterial.new()
		mat.gravity = Vector3(0, 200, 0)  # usa Vector3 aunque sea 2D
		mat.initial_velocity_min = 100
		mat.initial_velocity_max = 150
		mat.angular_velocity_min = -2.0
		mat.angular_velocity_max = 2.0
		mat.scale_min = 0.5
		mat.scale_max = 1.2
		particles.process_material = mat

		await get_tree().create_timer(1).timeout
		particles.queue_free()




func _add_shield() -> void:
	print("🛡️ FireBoss activa escudo temporal")
	var shield = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 40
	shield.shape = shape
	add_child(shield)
	await get_tree().create_timer(3).timeout
	shield.queue_free()

# =====================
#   DAÑO Y MUERTE
# =====================

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and Input.is_action_pressed("repel"):
		print("💥 Boss recibió ataque melee del jugador!")
		take_damage(melee_damage)
		return

	if body is Fireball and body.was_reflected:
		print("🔥 FireBoss golpeado por fireball reflejada")
		take_damage(20)
		body.queue_free()

func take_damage(amount: int) -> void:
	current_health -= amount
	current_health = clamp(current_health, 0, max_health)

	if has_node("Label"):
		$Label.text = str(current_health)

	print("🔥 FireBoss recibió", amount, "daño. Vida:", current_health)

	if current_health <= 0:
		_die()

func _die() -> void:
	print("💀 FireBoss derrotado")
	_spawn_explosion()
	if player:
		player.mode = player.Mode.COZY
	queue_free()
