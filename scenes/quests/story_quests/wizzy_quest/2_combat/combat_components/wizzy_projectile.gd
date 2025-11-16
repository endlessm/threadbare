extends Projectile
## Custom projectile for Wizzy Quest
## Cuando el jugador lo golpea, se "apaga" y puede ser empujado

## SpriteFrames para el estado apagado/desactivado
@export var disabled_sprite_frames: SpriteFrames

## Si está true, el proyectil está apagado y puede ser empujado
var is_disabled: bool = false

## Velocidades de deslizamiento
@export var walk_push_speed: float = 100.0  # Velocidad al empujar caminando
@export var attack_push_speed: float = 300.0  # Velocidad al atacar/empujar

## Si está deslizándose actualmente
var is_sliding: bool = false

## Referencia al collision shape original para modificar propiedades
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	super._ready()
	# Agregar al grupo para que el player lo encuentre
	add_to_group("pushable_projectiles")


func _process(_delta: float) -> void:
	if not is_disabled:
		return
	
	var player: Player = get_tree().get_first_node_in_group("player")
	if not player or player.mode != Player.Mode.FIGHTING:
		return
	
	var distance := global_position.distance_to(player.global_position)
	if distance > 100.0:
		return
	
	var direction := (global_position - player.global_position).normalized()
	
	# Si presiona atacar, empujar con más fuerza
	if Input.is_action_just_pressed(&"repel"):
		push(direction, attack_push_speed)
	# Si solo camina hacia el proyectil, empujar suavemente
	elif not is_sliding and distance < 40.0:
		push(direction, walk_push_speed)


func got_hit(player: Player) -> void:
	if is_disabled:
		# Si ya está apagado, no hacer nada
		return
	
	# Cambiar a estado apagado
	is_disabled = true
	
	# Detener completamente el proyectil
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	constant_force = Vector2.ZERO
	gravity_scale = 0.0
	
	# Desactivar el seguimiento
	node_to_follow = null
	
	# Cambiar al sprite apagado si existe
	if disabled_sprite_frames:
		animated_sprite_2d.sprite_frames = disabled_sprite_frames
		animated_sprite_2d.play()
	else:
		# Si no hay sprite apagado, oscurecer el actual
		modulate = Color(0.5, 0.5, 0.5, 1.0)
	
	# Desactivar colisión con el jugador - ahora el jugador puede empujarlo
	can_hit_player = false
	set_collision_mask_value(Enums.CollisionLayers.PLAYERS_HITBOX, false)
	
	# Cambiar a capa NON_WALKABLE_FLOOR
	set_collision_layer_value(Enums.CollisionLayers.PROJECTILES, false)
	set_collision_layer_value(Enums.CollisionLayers.NON_WALKABLE_FLOOR, true)
	
	# Configurar colisiones
	set_collision_mask_value(Enums.CollisionLayers.WALLS, true)
	set_collision_mask_value(Enums.CollisionLayers.PLAYERS, true)
	set_collision_mask_value(Enums.CollisionLayers.PROJECTILES, true)
	set_collision_mask_value(Enums.CollisionLayers.NON_WALKABLE_FLOOR, true)
	set_collision_mask_value(Enums.CollisionLayers.ENEMIES_HITBOX, false)
	
	# Configurar física tipo Goofy Troop: sin fricción, sin rebote
	mass = 3.0
	lock_rotation = true  # No rotar, mantener orientación
	gravity_scale = 0.0
	
	var new_material := PhysicsMaterial.new()
	new_material.friction = 0.0  # Sin fricción para deslizamiento continuo
	new_material.bounce = 0.0    # Sin rebote
	physics_material_override = new_material
	
	# Detener el timer de duración
	duration_timer.stop()
	
	# Reproducir efectos
	add_small_fx()
	hit_sound.play()


## Empuja el proyectil en una dirección (solo horizontal o vertical)
func push(direction: Vector2, speed: float = 0.0) -> void:
	if not is_disabled or is_sliding:
		return
	
	# Usar velocidad personalizada o la de ataque por defecto
	var push_speed := speed if speed > 0 else attack_push_speed
	
	# Normalizar a dirección cardinal
	var push_dir := Vector2(sign(direction.x), 0) if abs(direction.x) > abs(direction.y) else Vector2(0, sign(direction.y))
	
	is_sliding = true
	linear_velocity = push_dir * push_speed


# Sobrescribir para cambiar la lógica de barriles
func _on_body_entered(body: Node2D) -> void:
	if is_disabled:
		# Detener deslizamiento al chocar con algo
		if is_sliding:
			linear_velocity = Vector2.ZERO
			is_sliding = false
			add_small_fx()  # Efecto visual al chocar
		
		# Proyectil encendido choca con apagado
		if body is Projectile and not body.get("is_disabled"):
			body.explode()
			explode()
			return
		
		# Proyectil apagado disminuye barril
		if body.owner is FillingBarrel:
			var barrel: FillingBarrel = body.owner as FillingBarrel
			if barrel.label == label and barrel.has_method("decrement"):
				barrel.decrement()
				explode()
		# No hacer nada más cuando está apagado
		return
	
	# Proyectil encendido choca con apagado
	if body is Projectile and body.get("is_disabled"):
		body.explode()
		explode()
		return
	
	# Proyectil encendido aumenta barril
	add_small_fx()
	duration_timer.start()
	if body.owner is FillingBarrel:
		var barrel: FillingBarrel = body.owner as FillingBarrel
		if barrel.label == label:
			barrel.increment()
			queue_free()


# El proyectil apagado no debe explotar por timeout
func _on_duration_timer_timeout() -> void:
	if is_disabled:
		return
	super._on_duration_timer_timeout()
