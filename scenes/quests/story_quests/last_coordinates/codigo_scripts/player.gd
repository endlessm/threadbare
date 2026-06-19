@tool
extends Player

# 1. Interceptamos la función original del padre
func _set_speeds(new_speeds: CharacterSpeeds) -> void:
	# 2. Si la escena intenta mandar "null", creamos un objeto válido al instante
	if new_speeds == null:
		new_speeds = CharacterSpeeds.new()
	
	# 3. Le pasamos el objeto válido a la clase padre original para que siga su curso normal
	super._set_speeds(new_speeds)

func _physics_process(_delta: float) -> void:
	if mode == Mode.DEFEATED:
		return

	# Solo nos encargamos de procesar qué tocó el jugador
	_procesar_interacciones_fisicas()

func _procesar_interacciones_fisicas() -> void:
	for i in get_slide_collision_count():
		var colision = get_slide_collision(i)
		var collider = colision.get_collider()

		# Lógica del botón
		if collider and collider.is_in_group("boton"):
			collider.presionar()
		
		# Lógica de la caja
		if collider and collider.is_in_group("caja"):
			var direccion_empuje = -colision.get_normal()
			collider.empujar(direccion_empuje)
