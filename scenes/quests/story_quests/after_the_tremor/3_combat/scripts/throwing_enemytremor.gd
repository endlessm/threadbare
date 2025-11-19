extends ThrowingEnemy

@export var target_charlie: Node2D
@export var target_bryan: Node2D
@export var health_barrel: Node2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var current_phase: int = 1

func _ready():
	super._ready()
	# Iniciamos el ataque automáticamente o esperamos a que el Combat.gd lo haga
	# start() 

func _process(delta):
	super._process(delta)
	_check_phase()

func _check_phase():
	if not health_barrel: return
	
	# Calculamos porcentaje de vida restante (inverso a lo llenado)
	var hits_taken = health_barrel._amount # Accedemos a la variable interna del barril
	var max_hits = health_barrel.needed_amount
	
	# FASE 1: Inicio (0 a 33% de daño recibido)
	if hits_taken < max_hits * 0.33:
		current_phase = 1
		throwing_period = 2.5 # Lento
		
	# FASE 2: Mitad (33% a 66% de daño recibido)
	elif hits_taken < max_hits * 0.66:
		current_phase = 2
		throwing_period = 1.8 # Medio
		
	# FASE 3: Final (66% en adelante)
	else:
		current_phase = 3
		throwing_period = 1.2 # Frenético

# SOBRESCRIBIMOS LA FUNCIÓN DE DISPARO ORIGINAL
func shoot_projectile() -> void:
	# Dependiendo de la fase, elegimos a quién disparar
	match current_phase:
		1:
			# Fase 1: Solo ataca a uno al azar
			var target = _choose_random_target()
			_spawn_bullet(target)
			
		2:
			# Fase 2: Ataca a uno, pero más rápido (ya configurado en throwing_period)
			# Opcional: A veces dispara a los dos con poca probabilidad
			if randf() < 0.2: # 20% chance de ataque doble
				_attack_both()
			else:
				_spawn_bullet(_choose_random_target())
				
		3:
			# Fase 3: Alta probabilidad de ataque doble
			if randf() < 0.6: # 60% chance de ataque doble
				_attack_both()
			else:
				_spawn_bullet(_choose_random_target())

	_set_target_position() # Mantiene la lógica de movimiento original (aunque sea 0)

# Función auxiliar para elegir objetivo
func _choose_random_target() -> Node2D:
	if randi() % 2 == 0:
		return target_charlie
	else:
		return target_bryan

# Función para atacar a ambos (lanza dos proyectiles casi a la vez)
func _attack_both():
	_spawn_bullet(target_charlie)
	# Pequeña espera o inmediato
	_spawn_bullet(target_bryan)

# Lógica de instanciar bala (Copiada y adaptada del script original para dirigirla a un target específico)
func _spawn_bullet(target_node: Node2D):
	if not is_instance_valid(target_node): return
	
	var projectile = projectile_scene.instantiate()
	
	# CALCULAMOS LA DIRECCIÓN HACIA EL OBJETIVO ESPECÍFICO
	projectile.direction = projectile_marker.global_position.direction_to(target_node.global_position)
	
	scale.x = 1 if projectile.direction.x < 0 else -1
	
	# Configuración estándar del proyectil
	projectile.label = allowed_labels.pick_random()
	if projectile.label in color_per_label:
		projectile.color = color_per_label[projectile.label]
	
	projectile.global_position = projectile_marker.global_position + projectile.direction * distance
	
	# Si activas "follows player", le asignamos el target específico para que lo persiga
	if projectile_follows_player:
		projectile.node_to_follow = target_node # Asegúrate que tu proyectil tenga esta propiedad
		
	# Asignar assets
	projectile.sprite_frames = projectile_sprite_frames
	projectile.hit_sound_stream = projectile_hit_sound_stream
	projectile.small_fx_scene = projectile_small_fx_scene
	projectile.big_fx_scene = projectile_big_fx_scene
	projectile.trail_fx_scene = projectile_trail_fx_scene
	projectile.speed = projectile_speed
	projectile.duration = projectile_duration
	
	get_tree().current_scene.add_child(projectile)
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
