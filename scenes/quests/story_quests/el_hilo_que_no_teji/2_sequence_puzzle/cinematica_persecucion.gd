extends Area2D

@export var enemigo_vacio: Node2D

@export_group("Tiempos de la Cinemática")
@export var tiempo_viaje_ida: float = 1.2 # Segundos que tarda en llegar al monstruo
@export var tiempo_pausa_mirando: float = 1.1 # Segundos que lo ves correr hacia ti
@export var tiempo_viaje_vuelta: float = 0.8 # Segundos que tarda en regresar a Lino
@export var zoom_acercamiento: Vector2 = Vector2(1.4, 1.4) # Qué tanto zoom hace (1.0, 1.0 es el normal)

var secuencia_activada: bool = false

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or secuencia_activada:
		return
		
	secuencia_activada = true

	# 1. Congelar a Lino
	if body.has_method("take_control"):
		body.take_control(self)
	body.velocity = Vector2.ZERO

	# 2. Configurar cámara
	var camara = get_viewport().get_camera_2d()
	var zoom_original = camara.zoom
	var suavizado_original = camara.position_smoothing_enabled
	camara.position_smoothing_enabled = false

	# 3. LA CINEMÁTICA (Usando tus variables del Inspector)
	var cinematica = create_tween()
	
	# FASE A: El Vistazo suave
	cinematica.tween_property(camara, "global_position", enemigo_vacio.global_position, tiempo_viaje_ida).set_trans(Tween.TRANS_SINE)
	cinematica.parallel().tween_property(camara, "zoom", zoom_acercamiento, tiempo_viaje_ida)
	
	# FASE B: El Despertar
	cinematica.tween_callback(func():
		if enemigo_vacio and enemigo_vacio.has_method("start"):
			enemigo_vacio.start(body)
	)
	
	# FASE C: Parálisis (Pausa mientras se acerca)
	cinematica.tween_interval(tiempo_pausa_mirando) 
	
	# FASE D: El Regreso suave (Usamos TRANS_QUAD para no marear al jugador)
	cinematica.tween_property(camara, "global_position", body.global_position, tiempo_viaje_vuelta).set_trans(Tween.TRANS_QUAD)
	cinematica.parallel().tween_property(camara, "zoom", zoom_original, tiempo_viaje_vuelta)

	await cinematica.finished

	# 4. Restaurar y correr por tu vida
	camara.position_smoothing_enabled = suavizado_original
	camara.global_position = body.global_position 
	
	if body.has_method("return_control"):
		body.return_control(self)
