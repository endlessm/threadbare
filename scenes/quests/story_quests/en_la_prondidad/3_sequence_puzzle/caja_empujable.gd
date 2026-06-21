extends CharacterBody2D
class_name CajaEmpujable

## Controla qué tan rápido se detiene la caja sola (A menor número, más se desliza)
@export var friccion: float = 4.0

## Multiplica la fuerza con la que Nereo empuja la caja (A mayor número, más rápido se moverá)
@export var fuerza_multiplicadora: float = 1.5

func _physics_process(delta: float) -> void:
	# Anulamos cualquier fuerza de gravedad acumulada en el eje plano
	if not is_on_floor():
		velocity.y = move_toward(velocity.y, 0, 900 * delta)
		
	# Aplicamos la fricción para detener la caja gradualmente
	velocity = velocity.move_toward(Vector2.ZERO, friccion * delta * 100)
	
	# Mover la caja interactuando con el entorno
	var colision := move_and_slide()
	
	# TRUCO TOP-DOWN: Si Nereo está colisionando directamente contra la caja caminando,
	# detectamos su empuje nativo en tiempo real en este frame.
	if get_slide_collision_count() > 0:
		for i in range(get_slide_collision_count()):
			var col = get_slide_collision(i)
			if col.get_collider() is Player:
				# Tomamos la dirección en la que camina Nereo y la multiplicamos por su velocidad
				var jugador = col.get_collider()
				if "velocity" in jugador and jugador.velocity != Vector2.ZERO:
					empujar(jugador.velocity * fuerza_multiplicadora)

func empujar(fuerza_empuje: Vector2) -> void:
	velocity = fuerza_empuje
