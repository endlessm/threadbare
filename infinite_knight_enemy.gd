extends CharacterBody2D

signal died

@export var speed: float = 70.0
var player_target: Node2D = null 
var hp: int = 2
var is_stunned: bool = false
var is_attacking: bool = false # <- Controla si está preparando un golpe

# Variable para el pasito hacia atrás
var knockback_velocity: Vector2 = Vector2.ZERO

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player_target):
		if not is_stunned and not is_attacking:
			anim.play("idle")
		return
		
	# Calculamos la dirección hacia el jugador
	var direction: Vector2 = global_position.direction_to(player_target.global_position)
		
	# --- LÓGICA DE MOVIMIENTO ---
	if is_stunned:
		# Micro-deslizamiento suave hacia atrás mientras está aturdido
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 300.0 * delta)
	elif is_attacking:
		velocity = Vector2.ZERO # El enemigo se detiene para atacar
	else:
		velocity = direction * speed
		if direction.x != 0:
			anim.flip_h = direction.x < 0
		anim.play("walk")
			
	move_and_slide()
	
	# --- LÓGICA DE CHOQUE ---
	if is_stunned or is_attacking or get_slide_collision_count() == 0:
		return
		
	for i in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(i)
		var collider: Object = collision.get_collider()
		
		if collider == player_target:
			# En vez de hacer daño inmediato, iniciamos la secuencia
			_perform_attack(direction)
			break

# --- SECUENCIA DE ATAQUE (PERFECTAMENTE SINCRONIZADA) ---
func _perform_attack(hit_direction: Vector2) -> void:
	is_attacking = true
	
	# 1. WIND-UP: El enemigo se detiene a tomar impulso antes de golpear
	anim.play("idle") 
	
	# Esperamos 0.3 segundos para que el jugador pueda reaccionar
	await get_tree().create_timer(0.3).timeout
	
	# Si el enemigo murió o fue empujado por la espada en esos 0.3s, cancelamos el ataque
	if not is_instance_valid(self) or is_stunned:
		is_attacking = false
		return
		
	# 2. EL GOLPE: ¡Disparamos la animación en el frame exacto del impacto!
	anim.play("alerted")
		
	# Verificamos si el jugador sigue cerca (rango de 85 pixeles)
	if is_instance_valid(player_target) and global_position.distance_to(player_target.global_position) < 85.0:
		var arena: Node = get_tree().current_scene
		if arena.has_method("damage_player"):
			arena.damage_player()
			
	# 3. Micro-rebote hacia atrás después de atacar
	is_stunned = true
	knockback_velocity = -hit_direction * 50.0
	
	await get_tree().create_timer(0.5).timeout
	
	if is_instance_valid(self):
		is_stunned = false
		is_attacking = false

func receive_damage() -> void:
	hp -= 1
	if hp <= 0:
		# --- EL ÚNICO CAMBIO: AVISARLE A LA ARENA ---
		var arena: Node = get_tree().current_scene
		if arena.has_method("on_enemy_defeated"):
			arena.on_enemy_defeated()
		# ---------------------------------------------
		died.emit()
		queue_free()

# --- La función que busca la espada del jugador (VERSIÓN OMNIDIRECCIONAL 4 LADOS) ---
func got_repelled(push_direction: Vector2) -> void:
	var is_valid_hit: bool = false
	
	if is_instance_valid(player_target):
		# 1. Leemos hacia dónde intenta moverse el jugador (Arriba, Abajo, Izq, Der)
		var player_facing_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		
		# 2. Si el jugador está totalmente quieto, usamos la vista de su dibujo como plan B
		if player_facing_dir == Vector2.ZERO:
			var p_sprite: Node = player_target.find_child("PlayerSprite", true, false)
			if p_sprite and p_sprite.flip_h:
				player_facing_dir = Vector2.LEFT
			else:
				player_facing_dir = Vector2.RIGHT
		
		# 3. Magia matemática (Producto Punto)
		if push_direction.dot(player_facing_dir.normalized()) >= 0.1:
			is_valid_hit = true
			
	# Si el enemigo estaba a tu espalda o fuera del cono, ignoramos el golpe visual
	if not is_valid_hit:
		return

	# 4. Si el golpe fue válido en cualquiera de las 4 direcciones, aplicamos el daño
	receive_damage()
	
	if hp > 0:
		is_stunned = true
		knockback_velocity = push_direction * 200.0 
		anim.play("alerted")
		
		await get_tree().create_timer(0.5).timeout
		
		if is_instance_valid(self):
			is_stunned = false
