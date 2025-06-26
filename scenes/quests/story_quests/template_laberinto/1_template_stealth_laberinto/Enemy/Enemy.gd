extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var dust_particles: GPUParticles2D = $DustParticles

@export var WALK_SPEED: float = 200.0
@export var RUN_SPEED: float = 350.0
@export var run_duration: float = 2.0
@export var walk_duration: float = 4.0
@export var rango_ataque := 90.0
@export var dano := 10
@export var tiempo_entre_ataques := 0.8

var puede_atacar := true
var animacion_bloqueada := false
var esta_muerto := false
var vida := 50
var puede_moverse := true
var current_speed: float
var last_direction = Vector2.DOWN
var player: Node2D
var path_update_timer := 0.0
const PATH_UPDATE_INTERVAL := 0.2
var run_timer := 0.0
var is_running := false

func _ready() -> void:
	current_speed = WALK_SPEED
	navigation_agent.path_desired_distance = 4.0
	navigation_agent.target_desired_distance = 10.0
	navigation_agent.avoidance_enabled = true
	navigation_agent.path_max_distance = 1000.0
	navigation_agent.path_postprocessing = NavigationPathQueryParameters2D.PATH_POSTPROCESSING_EDGECENTERED
	navigation_agent.radius = 16.0
	navigation_agent.max_speed = RUN_SPEED

	setup_dust_particles()
	call_deferred("setup_navigation")

func recibir_daño(cantidad: int) -> void:
	vida -= cantidad
	puede_moverse = false
	if vida <= 0:
		queue_free()
	navigation_agent.set_velocity(Vector2.ZERO)
	animated_sprite_2d.play("golpeado")
	await get_tree().create_timer(0.3).timeout
	puede_moverse = true

func setup_dust_particles() -> void:
	if not dust_particles:
		dust_particles = GPUParticles2D.new()
		add_child(dust_particles)
	dust_particles.emitting = false
	dust_particles.amount = 15
	dust_particles.lifetime = 0.8
	dust_particles.position = Vector2(0, 10)

	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 20.0
	material.initial_velocity_max = 40.0
	material.angular_velocity_min = -180.0
	material.angular_velocity_max = 180.0
	material.gravity = Vector3(0, 50, 0)
	material.scale_min = 0.3
	material.scale_max = 0.7
	material.scale_over_velocity_min = 0.0
	material.scale_over_velocity_max = 0.1
	material.color = Color(0.8, 0.7, 0.5, 0.6)
	material.color_ramp = create_dust_gradient()

	dust_particles.process_material = material
	dust_particles.texture = create_dust_texture()

func create_dust_gradient() -> Gradient:
	var gradient = Gradient.new()
	gradient.colors = PackedColorArray([
		Color(0.8, 0.7, 0.5, 0.8),
		Color(0.6, 0.5, 0.3, 0.4),
		Color(0.4, 0.3, 0.2, 0.0)
	])
	gradient.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	return gradient

func create_dust_texture() -> ImageTexture:
	var image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	var center = Vector2(4, 4)

	for x in range(8):
		for y in range(8):
			var distance = Vector2(x, y).distance_to(center)
			var alpha = 1.0 - (distance / 4.0)
			alpha = max(0.0, alpha)
			image.set_pixel(x, y, Color(1, 1, 1, alpha))

	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func setup_navigation() -> void:
	await get_tree().physics_frame
	player = get_tree().get_first_node_in_group("player")
	if player:
		navigation_agent.target_position = player.global_position
	if not navigation_agent.velocity_computed.is_connected(_on_velocity_computed):
		navigation_agent.velocity_computed.connect(_on_velocity_computed)

func _physics_process(delta: float) -> void:
	if not puede_moverse:
		velocity = Vector2.ZERO
		handle_animations(Vector2.ZERO)
		return

	if not player:
		player = get_tree().get_first_node_in_group("player")
		if not player:
			handle_no_player()
			return

	intentar_atacar()
	update_speed(delta)
	navigation_agent.max_speed = current_speed
	
	path_update_timer += delta
	if path_update_timer >= PATH_UPDATE_INTERVAL:
		path_update_timer = 0.0
		if player and navigation_agent.target_position.distance_to(player.global_position) > 5.0:
			navigation_agent.target_position = player.global_position

	if not navigation_agent.is_navigation_finished():
		var next_path_position = navigation_agent.get_next_path_position()
		var direction = global_position.direction_to(next_path_position)
		if direction.length() > 0:
			var desired_velocity = direction * current_speed
			if navigation_agent.avoidance_enabled:
				navigation_agent.set_velocity(desired_velocity)
			else:
				_on_velocity_computed(desired_velocity)
			handle_animations(direction)
		else:
			velocity = Vector2.ZERO
			handle_animations(Vector2.ZERO)
	else:
		velocity = Vector2.ZERO
		handle_animations(Vector2.ZERO)
	
	update_dust_particles()

func update_speed(delta: float) -> void:
	run_timer += delta
	if is_running:
		current_speed = RUN_SPEED
		if run_timer >= run_duration:
			is_running = false
			run_timer = 0.0
	else:
		current_speed = WALK_SPEED
		if run_timer >= walk_duration:
			is_running = true
			run_timer = 0.0

func update_dust_particles() -> void:
	if dust_particles:
		var is_moving = velocity.length() > 10.0
		dust_particles.emitting = is_running and is_moving

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()

func handle_no_player() -> void:
	velocity = Vector2.ZERO
	if dust_particles:
		dust_particles.emitting = false

	var anim_name = ""
	if abs(last_direction.x) >= abs(last_direction.y):
		anim_name = "IdleDerecha" if last_direction.x > 0 else "IdleIzquierda"
	else:
		anim_name = "IdleAbajo" if last_direction.y > 0 else "IdleArriba"

	if animated_sprite_2d and animated_sprite_2d.animation != anim_name:
		animated_sprite_2d.play(anim_name)

func handle_animations(movement_vector: Vector2) -> void:
	if not animated_sprite_2d or animacion_bloqueada:
		return
	if movement_vector != Vector2.ZERO:
		last_direction = movement_vector
	var is_moving = velocity.length() > 5.0
	var anim_name = ""
	if is_moving:
		anim_name = "MoveDerecha"
	if animated_sprite_2d.animation != anim_name:
		animated_sprite_2d.play(anim_name)

func intentar_atacar() -> void:
	if not puede_atacar or not player:
		return
	if global_position.distance_to(player.global_position) <= rango_ataque:
		puede_atacar = false
		puede_moverse = false
		animacion_bloqueada = true
		animated_sprite_2d.play("golpeado")
		if player.has_method("recibir_daño"):
			player.recibir_daño(dano)
		await get_tree().create_timer(0.5).timeout
		animacion_bloqueada = false
		puede_moverse = true
		await get_tree().create_timer(tiempo_entre_ataques - 0.5).timeout
		puede_atacar = true
