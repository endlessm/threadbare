extends CharacterBody2D

@onready var detection_area: Area2D = $detection_area
@onready var navigation_agent: NavigationAgent2D = $navigation_agent
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

@export var FLY_SPEED: float = 150.0
@export var idle_duration: float = 3.0
@export var move_duration: float = 2.5
@export var detection_radius: float = 80.0
@export var flee_distance: float = 200.0

var current_speed: float = 0.0
var player: Node2D
var state: String = "idle"  # "idle", "moving", "fleeing"
var state_timer: float = 0.0
var target_position: Vector2
var initial_position: Vector2
var roam_area_radius: float = 300.0
var last_direction: Vector2 = Vector2.RIGHT
var rotation_speed: float = 5.0  # Velocidad de rotación suave

func _ready() -> void:
	initial_position = global_position
	current_speed = 0.0
	
	# Configuración del NavigationAgent2D
	navigation_agent.path_desired_distance = 8.0
	navigation_agent.target_desired_distance = 15.0
	navigation_agent.avoidance_enabled = false  # Las mariposas no necesitan evitar obstáculos tanto
	navigation_agent.path_max_distance = 500.0
	navigation_agent.radius = 8.0
	navigation_agent.max_speed = FLY_SPEED
	
	# Configurar área de detección
	setup_detection_area()
	call_deferred("setup_navigation")
	
	# Comenzar en estado idle
	change_state("idle")

func setup_detection_area() -> void:
	if not detection_area:
		detection_area = Area2D.new()
		add_child(detection_area)
		
		var collision_shape = CollisionShape2D.new()
		var circle_shape = CircleShape2D.new()
		circle_shape.radius = detection_radius
		collision_shape.shape = circle_shape
		detection_area.add_child(collision_shape)
	
	detection_area.body_entered.connect(_on_player_detected)


func create_wing_gradient() -> Gradient:
	var gradient = Gradient.new()
	gradient.colors = PackedColorArray([
		Color(0.4, 0.7, 1.0, 0.8),  # Azul claro
		Color(0.2, 0.5, 0.9, 0.5),  # Azul medio
		Color(0.1, 0.3, 0.7, 0.0)   # Azul oscuro transparente
	])
	gradient.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
	return gradient

func create_wing_texture() -> ImageTexture:
	var image = Image.create(6, 6, false, Image.FORMAT_RGBA8)
	var center = Vector2(3, 3)
	
	for x in range(6):
		for y in range(6):
			var distance = Vector2(x, y).distance_to(center)
			var alpha = 1.0 - (distance / 3.0)
			alpha = max(0.0, alpha)
			image.set_pixel(x, y, Color(1, 1, 1, alpha))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func setup_navigation() -> void:
	await get_tree().physics_frame
	
	player = get_tree().get_first_node_in_group("player")
	
	if not navigation_agent.velocity_computed.is_connected(_on_velocity_computed):
		navigation_agent.velocity_computed.connect(_on_velocity_computed)

func _physics_process(delta: float) -> void:
	if not player:
		player = get_tree().get_first_node_in_group("player")
	
	state_timer += delta
	
	match state:
		"idle":
			handle_idle_state(delta)
		"moving":
			handle_moving_state(delta)
		"fleeing":
			handle_fleeing_state(delta)
	
	# Actualizar navegación si hay objetivo
	if state != "idle" and not navigation_agent.is_navigation_finished():
		var next_path_position = navigation_agent.get_next_path_position()
		var direction = global_position.direction_to(next_path_position)
		
		if direction.length() > 0:
			last_direction = direction  # Guardar la dirección para rotación
			var desired_velocity = direction * current_speed
			_on_velocity_computed(desired_velocity)
		else:
			velocity = Vector2.ZERO
	else:
		velocity = Vector2.ZERO
	
	update_sprite_rotation(delta)
	handle_animations()

func handle_idle_state(delta: float) -> void:
	current_speed = 0.0
	
	# Cambiar a moving después del tiempo de idle
	if state_timer >= idle_duration:
		change_state("moving")

func handle_moving_state(delta: float) -> void:
	current_speed = FLY_SPEED
	
	# Si no tenemos objetivo o hemos llegado, elegir nuevo punto
	if navigation_agent.is_navigation_finished() or target_position == Vector2.ZERO:
		choose_random_destination()
	
	# Cambiar a idle después del tiempo de movimiento
	if state_timer >= move_duration:
		change_state("idle")

func handle_fleeing_state(delta: float) -> void:
	current_speed = FLY_SPEED * 1.2  # Volar más rápido cuando huye
	
	# Si hemos llegado al punto de escape, cambiar a moving
	if navigation_agent.is_navigation_finished():
		change_state("moving")

func change_state(new_state: String) -> void:
	state = new_state
	state_timer = 0.0
	
	match state:
		"idle":
			target_position = Vector2.ZERO
		"moving":
			choose_random_destination()
		"fleeing":
			choose_flee_destination()

func choose_random_destination() -> void:
	# Elegir un punto aleatorio dentro del área de roaming
	var angle = randf() * TAU
	var distance = randf() * roam_area_radius
	target_position = initial_position + Vector2(cos(angle), sin(angle)) * distance
	navigation_agent.target_position = target_position

func choose_flee_destination() -> void:
	if not player:
		choose_random_destination()
		return
	
	# Huir en dirección opuesta al jugador
	var flee_direction = global_position.direction_to(player.global_position) * -1
	target_position = global_position + flee_direction * flee_distance
	navigation_agent.target_position = target_position

func _on_player_detected(body: Node2D) -> void:
	if body.is_in_group("player") and state == "idle":
		change_state("fleeing")

func update_sprite_rotation(delta: float) -> void:
	if not animated_sprite_2d:
		return
	
	# Solo rotar cuando se esté moviendo
	if state != "idle" and velocity.length() > 5.0:
		var target_angle = last_direction.angle() + PI/2
		var current_angle = animated_sprite_2d.rotation
		
		# Interpolación suave entre el ángulo actual y el objetivo
		var angle_diff = angle_difference(current_angle, target_angle)
		animated_sprite_2d.rotation += angle_diff * rotation_speed * delta

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()

func handle_animations() -> void:
	if not animated_sprite_2d:
		return
	
	var anim_name = ""
	
	if state == "idle" or velocity.length() < 5.0:
		anim_name = "Idle"
	else:
		anim_name = "Move"
	
	if animated_sprite_2d.animation != anim_name:
		animated_sprite_2d.play(anim_name)
