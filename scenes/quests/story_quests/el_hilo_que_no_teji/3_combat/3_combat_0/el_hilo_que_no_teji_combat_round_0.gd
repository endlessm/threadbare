# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

# RUTAS ADAPTADAS DE FORMA SEGURA
@onready var jugador: CharacterBody2D = $OnTheGround/Player
@onready var luto: CharacterBody2D = $OnTheGround/Luto 
@onready var luto_sprite: AnimatedSprite2D = $OnTheGround/Luto/AnimatedSprite2D

@onready var cinematic: Cinematic = $Cinematic
@onready var detector_dialogo: Area2D = $OnTheGround/DetectorDialogo

# MARCADORES EXPORTADOS AL INSPECTOR
@export var punto_parada_lino: Marker2D 
@export var posicion_junto_a_lazaro: Marker2D

var secuencia_activada: bool = false

func _ready() -> void:
	# Desactivamos el autostart de la cinemática por código para controlar el orden nosotros
	cinematic.autostart = false
	
	# --- SOLUCIÓN DIRECTA SIN GRUPOS NI RUTAS ---
	# propagate_call rastrea el árbol de la escena y le manda la orden de apagado 
	# exclusivamente al nodo que tiene esta función (tu HUD).
	get_tree().root.propagate_call("change_story_quest_progress_visibility", [false])
	# --------------------------------------------
	
	# Al cargar la escena, Luto corre solo hacia arriba
	hacer_que_luto_corra()

func hacer_que_luto_corra() -> void:
	# Luto reproduce su animación de caminar/correr
	luto_sprite.play("walk") 
	
	var tween = create_tween()
	tween.tween_property(luto, "global_position", posicion_junto_a_lazaro.global_position, 2.0)
	await tween.finished
	
	# Al llegar al marcador al lado de Lázaro, se queda quieto
	luto_sprite.play("idle") 

# Esta función se activa sola cuando Lino pisa el rectángulo invisible
func _on_detector_dialogo_body_entered(body: Node2D) -> void:
	# Filtramos por el nombre exacto de tu nodo "Player"
	if body.name == "Player" and not secuencia_activada:
		secuencia_activada = true
		comenzar_secuencia_cinematica()

func comenzar_secuencia_cinematica() -> void:
	# Frenamos inmediatamente cualquier velocidad previa del jugador
	jugador.velocity = Vector2.ZERO
	await get_tree().physics_frame

	# Bucle para mover a Lino paso a paso de forma realista hasta que llegue al marcador
	while jugador.global_position.distance_to(punto_parada_lino.global_position) > 5.0:
		# Calculamos hacia dónde caminar en este fotograma (hacia arriba)
		var direccion = (punto_parada_lino.global_position - jugador.global_position).normalized()
		
		# Le inyectamos la velocidad directamente a su física de movimiento
		jugador.velocity = direccion * 80.0 
		jugador.move_and_slide()
		
		# Como tu Player tiene las animaciones integradas directamente, lo llamamos a él
		if jugador.has_method("play") and jugador.animation != "walk":
			jugador.play("walk")
			
		# Esperamos un solo fotograma de física antes de continuar el bucle
		await get_tree().physics_frame

	# 2. Una vez que llega al punto exacto, lo frenamos por completo
	jugador.velocity = Vector2.ZERO
	
	# Ponemos la animación quieta y lo obligamos a mirar a la derecha (flip_h = false)
	if jugador.has_method("play"):
		jugador.play("idle")
	if "flip_h" in jugador:
		jugador.flip_h = false

	# Le quitamos el control del teclado al jugador temporalmente para el diálogo
	jugador.set_physics_process(false)

	# 3. Iniciamos el diálogo automático con Lázaro
	cinematic.start()
	await cinematic.cinematic_finished 

	# 4. APERTURA BLINDADA POR GRUPO (Solución definitiva al error de rutas):
	var puerta_secreta = get_tree().get_first_node_in_group("puerta_cinematica")
	
	if puerta_secreta != null:
		if puerta_secreta.has_method("abrir_puerta_secreta"):
			puerta_secreta.abrir_puerta_secreta()
		else:
			print("Error: El nodo encontrado no tiene la función abrir_puerta_secreta")
	else:
		print("Error Crítico: No se encontró la puerta.")

	# 5. Le devolvemos el control completo del teclado al jugador para que continúe
	jugador.set_physics_process(true)
