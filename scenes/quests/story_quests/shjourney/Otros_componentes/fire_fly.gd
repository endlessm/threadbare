extends Node2D

var speed = 15.0
var direction = Vector2.RIGHT
var timer = 0.0
var direction_change_timer = 0.0

# Posición inicial para mantener la luciérnaga en su área
var home_position: Vector2
var max_distance = 80.0  # Radio máximo desde su posición inicial

# Variables para el brillo
var glow_timer = 0.0
var glow_cycle_time = 3.0  # Tiempo para un ciclo completo de brillo
var is_glowing = true

func _ready():
	# Guardar posición inicial como "hogar"
	home_position = position
	
	# Dirección aleatoria inicial más suave
	direction = Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5)).normalized()
	
	# Velocidad más lenta y realista
	speed = randf_range(12, 20)
	
	# Ciclo de brillo aleatorio para cada luciérnaga
	glow_cycle_time = randf_range(2.5, 4.0)

func _process(delta):
	timer += delta
	direction_change_timer += delta
	glow_timer += delta
	
	# Movimiento suave y flotante
	move_firefly(delta)
	
	# Cambiar dirección más frecuentemente pero con cambios más suaves
	if direction_change_timer > randf_range(1.0, 2.0):
		change_direction()
		direction_change_timer = 0.0
	
	# Efecto de brillo realista (se apaga y enciende)
	realistic_glow_effect()

func move_firefly(delta):
	# Calcular nueva posición
	var new_position = position + direction * speed * delta
	
	# Verificar si se aleja demasiado del hogar
	var distance_from_home = home_position.distance_to(new_position)
	
	if distance_from_home > max_distance:
		# Si se aleja mucho, dirigirse de vuelta al hogar
		direction = (home_position - position).normalized()
		# Añadir un poco de aleatoriedad para que no sea muy mecánico
		direction = direction.rotated(randf_range(-0.3, 0.3))
	
	# Aplicar el movimiento
	position += direction * speed * delta
	
	# Añadir flotación natural (movimiento ondulante)
	var float_offset = Vector2(
		sin(timer * 2.0) * 3.0,
		cos(timer * 1.5) * 2.0
	)
	position += float_offset * delta

func change_direction():
	# Cambio de dirección más natural
	var angle_change = randf_range(-1.0, 1.0)  # Cambio más sutil
	direction = direction.rotated(angle_change)
	
	# Ocasionalmente hacer un cambio más dramático (como si esquivara algo)
	if randf() < 0.2:  # 20% de probabilidad
		direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()

func realistic_glow_effect():
	var light_node = $PointLight2D
	var sprite_node = $Sprite2D
	
	if not light_node or not sprite_node:
		return
	
	# Ciclo de brillo realista: se apaga completamente y vuelve a aparecer
	var glow_progress = glow_timer / glow_cycle_time
	
	if glow_progress >= 1.0:
		glow_timer = 0.0
		glow_cycle_time = randf_range(2.5, 4.0)  # Nuevo ciclo aleatorio
	
	var brightness = 0.0
	
	# Patrón de brillo de luciérnaga real
	if glow_progress < 0.1:
		# Encendido rápido
		brightness = glow_progress / 0.1
	elif glow_progress < 0.3:
		# Brillo pleno
		brightness = 1.0
	elif glow_progress < 0.5:
		# Apagado gradual
		brightness = 1.0 - ((glow_progress - 0.3) / 0.2)
	else:
		# Apagado (la mayor parte del tiempo)
		brightness = 0.0
		
		# Pequeños destellos ocasionales mientras está "apagada"
		if randf() < 0.05:  # 5% probabilidad cada frame
			brightness = randf_range(0.1, 0.3)
	
	# Aplicar el brillo con un poco de variación
	var final_brightness = brightness * randf_range(0.8, 1.2)
	light_node.energy = final_brightness * 1.2
	sprite_node.modulate.a = final_brightness
