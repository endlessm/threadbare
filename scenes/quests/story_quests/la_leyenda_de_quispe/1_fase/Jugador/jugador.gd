extends CharacterBody2D

@export var speed: float = 200.0
@export var max_health: int = 150
@export var invulnerability_time: float = 1.0
@export var bullet_scene: PackedScene
@export var shoot_cooldown: float = 0.4 
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
var current_health: int = 0
var invulnerable: bool = false
var is_dead: bool = false
var can_shoot: bool = true
var is_attacking: bool = false
var last_direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	animated_sprite.play("Iddle")
	animated_sprite.animation_finished.connect(_on_animation_finished)
	add_to_group("player")
	current_health = max_health
	var invul_timer: Timer = Timer.new()
	invul_timer.name = "InvulTimer"
	invul_timer.one_shot = true
	invul_timer.wait_time = invulnerability_time
	add_child(invul_timer)
	invul_timer.timeout.connect(_on_invul_timeout)

func _physics_process(_delta: float) -> void:
	if is_dead:
		return
	var dir: Vector2 = Vector2.ZERO
	dir.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	dir.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	if dir != Vector2.ZERO:
		last_direction = dir.normalized()
		if dir.x != 0:
			animated_sprite.flip_h = (dir.x < 0)
	velocity = dir.normalized() * speed
	move_and_slide()
	if Input.is_action_pressed("interact") and can_shoot:
		shoot()
	if is_attacking:
		return
	if velocity.is_zero_approx():
		if animated_sprite.animation != "Iddle":
			animated_sprite.play("Iddle")
	else:
		if animated_sprite.animation != "Walk":
			animated_sprite.play("Walk")

func shoot() -> void:
	if bullet_scene == null:
		print("⚠️ ¡Falta asignar la bullet_scene en el Inspector!")
		return
	can_shoot = false
	is_attacking = true
	animated_sprite.play("Battle")
	var bullet: Area2D = bullet_scene.instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = global_position
	var shoot_direction: Vector2 = Vector2.UP
	if animated_sprite.flip_h:
		shoot_direction = Vector2.UP
	if "direction" in bullet:
		bullet.direction = shoot_direction
	bullet.rotation = shoot_direction.angle()
	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true

func _on_animation_finished() -> void:
	if animated_sprite.animation == "Battle":
		is_attacking = false

func take_damage(amount: int) -> void:
	if invulnerable or current_health <= 0 or is_dead:
		return
	current_health -= amount
	print("💥 Jugador recibió daño. Vida:", current_health)
	invulnerable = true
	$InvulTimer.start()
	blink()
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

func die() -> void:
	if is_dead: return 
	is_dead = true
	print("💀 Jugador derrotado")
	velocity = Vector2.ZERO 
	if animated_sprite.sprite_frames.has_animation("defeated"):
		animated_sprite.play("defeated") 
	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()
