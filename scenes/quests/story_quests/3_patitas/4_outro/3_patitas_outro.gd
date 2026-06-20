extends Node2D

# 1. DEFINICIONES DE NODOS
@onready var gato = $OnTheGround/Character
@onready var conejo = $OnTheGround/ConejoGame
@onready var gato_sabio = $OnTheGround/GatoSabio

# Dejamos la cámara libre aquí, la buscaremos de forma inteligente en el _ready
var camara: Camera2D

# 2. VARIABLES DE CONFIGURACIÓN Y POSICIÓN
var gato_base_pos: Vector2
var conejo_base_pos: Vector2
var gato_sabio_base_pos: Vector2

var tiempo = 0.0
var velocidad_gato = 250.0 

func _ready() -> void:
	# 🔍 DETECTOR AUTOMÁTICO: Busca la cámara en toda la escena para evitar errores de rutas
	camara = find_child("Camera2D", true, false) as Camera2D
	
	# Guardamos las posiciones iniciales del editor
	gato_base_pos = gato.position
	conejo_base_pos = conejo.position
	gato_sabio_base_pos = gato_sabio.position
	
	# Si encuentra la cámara, la encendemos y la obligamos a mandar en la pantalla
	if camara:
		camara.enabled = true
		camara.make_current()

func _process(delta: float) -> void:
	tiempo += delta
	
	# ====================================================
	# CONTROL DEL GATO PRINCIPAL (FLECHAS + BRINCO AL PARAR)
	# ====================================================
	var direccion = Vector2.ZERO
	
	if Input.is_action_pressed("ui_right"):
		direccion.x += 1
	if Input.is_action_pressed("ui_left"):
		direccion.x -= 1
	if Input.is_action_pressed("ui_down"):
		direccion.y += 1
	if Input.is_action_pressed("ui_up"):
		direccion.y -= 1
	
	if direccion != Vector2.ZERO:
		direccion = direccion.normalized()
		gato_base_pos += direccion * velocidad_gato * delta
		gato.position = gato_base_pos
	else:
		gato.position.x = gato_base_pos.x
		gato.position.y = gato_base_pos.y + sin(tiempo * 8.0) * 15.0

	# ====================================================
	# 🎥 SEGUIMIENTO INCONDICIONAL DE CÁMARA (CÓDIGO PURO)
	# ====================================================
	if camara:
		# LERP hace que la cámara persiga al gato de forma fluida y elegante.
		# No importa si la cámara está afuera, adentro o amarrada a otro lado;
		# esta línea actualiza su posición global directamente hacia el gato naranja.
		camara.global_position = camara.global_position.lerp(gato.global_position, 8.0 * delta)

	# ====================================================
	# EL CONEJO (SOLO BRINCA AUTOMÁTICO)
	# ====================================================
	conejo.position.x = conejo_base_pos.x
	conejo.position.y = conejo_base_pos.y + sin(tiempo * 8.0 + 1.5) * 20.0

	# ====================================================
	# GATO SABIO (SOLO BRINCA AUTOMÁTICO)
	# ====================================================
	gato_sabio.position.x = gato_sabio_base_pos.x
	gato_sabio.position.y = gato_sabio_base_pos.y + sin(tiempo * 8.0 + 3.0) * 15.0
