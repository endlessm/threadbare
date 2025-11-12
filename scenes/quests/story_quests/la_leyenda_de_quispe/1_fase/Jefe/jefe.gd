extends CharacterBody2D

@export var speed: float = 70.0
@export var move_distance: float = 250.0
@export var bullet_scene: PackedScene
@export var bullet_speed: float = 300.0
@export var random_fire_range: Vector2 = Vector2(1.0, 3.0)
@export var shoot_direction: Vector2 = Vector2.LEFT
@export var aim_at_player: bool = true
@export var fan_shot_angle: float = 40.0
@export var fan_shot_count: int = 5
@export var fan_shot_chance: float = 0.5
@export var max_health: int = 3400
@export var invulnerability_time: float = 1.0
@export var special_bullet_scene: PackedScene
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
var player_in_range: bool = false
var start_position: Vector2
var moving_right: bool = true
var current_health: int = 0
var invulnerable: bool = false
var hits_taken: int = 0
var is_dead: bool = false
var is_attacking: bool = false

func _ready() -> void:
	randomize()
	start_position = position
	current_health = max_health
	add_to_group("boss")
	animated_sprite.play("walk") 
	if $Area2D:
		$Area2D.body_entered.connect(_on_Area2D_body_entered)
		$Area2D.body_exited.connect(_on_Area2D_body_exited)
	else:
		push_error("❌ No se encontró el nodo Area2D en el jefe")
	if not $ShootTimer:
		push_error("❌ Falta el nodo Timer llamado 'ShootTimer'.")
		return
	$ShootTimer.wait_time = randf_range(random_fire_range.x, random_fire_range.y)
	if not $ShootTimer.timeout.is_connected(_on_shoot_timer_timeout):
		$ShootTimer.timeout.connect(_on_shoot_timer_timeout)
	$ShootTimer.stop()
	if not has_node("InvulTimer"):
		var invul_timer: Timer = Timer.new()
		invul_timer.name = "InvulTimer"
		invul_timer.one_shot = true
		invul_timer.wait_time = invulnerability_time
		add_child(invul_timer)
		invul_timer.timeout.connect(_on_invul_timeout)

func _process(_delta: float) -> void:
	if is_dead or is_attacking:
		return
	move_side_to_side(_delta)

func move_side_to_side(delta: float) -> void:
	if animated_sprite.animation != "walk":
		animated_sprite.play("walk")

	if moving_right:
		animated_sprite.flip_h = false
		position.x += speed * delta
		if position.x > start_position.x + move_distance:
			moving_right = false
	else:
		animated_sprite.flip_h = true
		position.x -= speed * delta
		if position.x < start_position.x - move_distance:
			moving_right = true

func _on_Area2D_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		print("👀 Jugador detectado cerca del jefe — comenzando disparos")
		$ShootTimer.start()

func _on_Area2D_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		print("🚶‍♂️ Jugador salió del rango — deteniendo disparos")
		$ShootTimer.stop()

func _on_shoot_timer_timeout() -> void:
	print("⏱️ Timer activado")
	if not player_in_range or is_attacking or is_dead:
		print("Jugador fuera de rango, no dispara")
		$ShootTimer.start()
		return
	is_attacking = true
	animated_sprite.play("attack anticipation")
	await animated_sprite.animation_finished
	animated_sprite.play("attack")
	print("💥 Disparando...")
	if randf() < fan_shot_chance:
		shoot_circle()
	else:
		shoot_single()
	await animated_sprite.animation_finished
	is_attacking = false
	$ShootTimer.wait_time = randf_range(random_fire_range.x, random_fire_range.y)
	$ShootTimer.start()

func shoot_single() -> void:
	if bullet_scene == null or not $SpawnPoint:
		return
	var bullet: Node2D = bullet_scene.instantiate()
	bullet.position = $SpawnPoint.global_position
	bullet.set("owner_type", "boss")
	bullet.set("direction", (get_player_direction() if aim_at_player else shoot_direction).normalized())
	bullet.set("speed", bullet_speed)
	get_tree().current_scene.add_child(bullet)

func shoot_circle() -> void:
	if bullet_scene == null or not $SpawnPoint:
		return
	var bullet_count: int = 12
	var radius: float = 40
	var dir_to_player: Vector2 = (get_player_direction() if aim_at_player else shoot_direction).normalized()
	var angle_step: float = 2 * PI / bullet_count
	var center: Vector2 = $SpawnPoint.global_position + dir_to_player * 50
	for i in range(bullet_count):
		var angle: float = i * angle_step
		var offset: Vector2 = Vector2(cos(angle), sin(angle)) * radius
		var bullet: Node2D = bullet_scene.instantiate()
		bullet.position = center + offset
		bullet.owner_type = "boss"
		bullet.direction = dir_to_player
		bullet.speed = bullet_speed
		get_tree().current_scene.add_child(bullet)

func get_player_direction() -> Vector2:
	var player: Node2D = get_tree().get_first_node_in_group("player")
	if player:
		return (player.global_position - global_position).normalized()
	return Vector2.ZERO

func take_damage(amount: int) -> void:
	if invulnerable or current_health <= 0 or is_dead:
		return
	current_health -= amount
	hits_taken += 1
	print("💥 Jefe recibió ", amount, " de daño. Vida restante:", current_health)
	invulnerable = true
	$InvulTimer.start()
	blink()
	if hits_taken % 5 == 0:
		shoot_triangle_attack()
	if current_health <= 0:
		die()

func _on_invul_timeout() -> void:
	invulnerable = false
	modulate = Color(1, 1, 1)

func blink() -> void:
	var blink_tween: Tween = get_tree().create_tween()
	blink_tween.tween_property(self, "modulate", Color(1, 1, 1, 0.3), 0.1)
	blink_tween.tween_property(self, "modulate", Color(1, 1, 1), 0.1)
	blink_tween.set_loops(5)

func shoot_triangle_attack() -> void:
	if special_bullet_scene == null or not $SpawnPoint:
		print("⚠️ No hay bala especial asignada o falta SpawnPoint.")
		return
	print("☀️ ¡Ataque especial del jefe activado!")
	var special_bullet: Node2D = special_bullet_scene.instantiate()
	special_bullet.position = $SpawnPoint.global_position
	special_bullet.set("direction", (get_player_direction() if aim_at_player else shoot_direction).normalized())
	get_tree().current_scene.add_child(special_bullet)

func die() -> void:
	if is_dead:
		return
	is_dead = true
	$ShootTimer.stop()
	print("💀 Jefe derrotado")
	animated_sprite.play("defeated")
	await animated_sprite.animation_finished 
	queue_free()
