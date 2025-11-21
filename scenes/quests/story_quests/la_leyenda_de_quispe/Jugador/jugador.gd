extends CharacterBody2D

@export var speed: float = 200.0
@export var run_speed: float = 350.0 
@export var max_health: int = 150
@export var invulnerability_time: float = 1.0
@export var bullet_scene: PackedScene
@export var shoot_cooldown: float = 0.4 
@export var charge_threshold: float = 0.5
@export var charged_shot_scale: float = 2.0
@export var lock_camera: bool = false
@export var fixed_camera_position: Vector2 = Vector2.ZERO
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
var is_charging: bool = false
var charge_timer: float = 0.0
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
	if DatosGlobales.primera_carga:
		DatosGlobales.max_health = max_health
		DatosGlobales.current_health = max_health
		DatosGlobales.primera_carga = false
	current_health = DatosGlobales.current_health
	max_health = DatosGlobales.max_health
	var invul_timer: Timer = Timer.new()
	invul_timer.name = "InvulTimer"
	invul_timer.one_shot = true
	invul_timer.wait_time = invulnerability_time
	add_child(invul_timer)
	invul_timer.timeout.connect(_on_invul_timeout)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	var dir: Vector2 = Vector2.ZERO
	dir.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	dir.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	if dir != Vector2.ZERO:
		last_direction = dir.normalized()
		if dir.x != 0:
			animated_sprite.flip_h = (dir.x < 0)
	var current_speed: float = speed
	if Input.is_action_pressed("running") and dir != Vector2.ZERO:
		current_speed = run_speed
	velocity = dir.normalized() * current_speed
	move_and_slide()
	if Input.is_action_just_pressed("interact") and can_shoot:
		is_charging = true
		charge_timer = 0.0
	if is_charging:
		charge_timer += delta
		if Input.is_action_just_released("interact"):
			is_charging = false
			if charge_timer >= charge_threshold:
				shoot(true)
			else:
				shoot(false)	
	if is_attacking:
		return
	if velocity.is_zero_approx():
		if animated_sprite.animation != "Iddle":
			animated_sprite.play("Iddle")
	else:
		if Input.is_action_pressed("running") and animated_sprite.sprite_frames.has_animation("Run"):
			if animated_sprite.animation != "Run":
				animated_sprite.play("Run")
		else:
			if animated_sprite.animation != "Walk":
				animated_sprite.play("Walk")

func shoot(is_charged: bool) -> void:
	if bullet_scene == null:
		print("⚠️ ¡Falta asignar la bullet_scene en el Inspector!")
		return
	can_shoot = false
	is_attacking = true
	animated_sprite.play("Battle")
	var bullet: Area2D = bullet_scene.instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = global_position
	if is_charged:
		print("🔥 ¡DISPARO CARGADO!")
		bullet.damage = bullet.damage * 2
		bullet.scale = Vector2(charged_shot_scale, charged_shot_scale)
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
	DatosGlobales.current_health = current_health
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
	DatosGlobales.current_health = DatosGlobales.max_health
	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()

func activar_camara_fija() -> void:
	print("⚡ INTENTANDO ACTIVAR CÁMARA FIJA...")
	if not lock_camera:
		print("❌ ERROR: La casilla 'Lock Camera' no está activada en el Inspector.")
		return
	if has_node("Camera2D"):
		var cam: Camera2D = $Camera2D
		cam.top_level = true 
		cam.limit_left = -10000000
		cam.limit_top = -10000000
		cam.limit_right = 10000000
		cam.limit_bottom = 10000000
		print("✅ Moviendo cámara de ", cam.global_position, " a ", fixed_camera_position)
		var tween: Tween = get_tree().create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(cam, "global_position", fixed_camera_position, 1.5)
	else:
		print("⚠️ ERROR: No se encontró el nodo Camera2D")
