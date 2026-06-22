extends Area2D

@onready var sprite = $Sprite2D
@onready var timer = $Timer

# 2 = Estado Inicial (Textura con diseño base)
# 1 = Degradación fase 1 (Agrietándose)
# 0 = Degradación fase 2 (A punto de romperse)
# -1 = Roto por completo (Vacío / Cae al fondo)
var fase_actual: int = 2 
var jugador_encima: bool = false

func _ready() -> void:
	sprite.frame = fase_actual
	sprite.visible = true
	timer.one_shot = true 

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"): 
		jugador_encima = true
		
		# Si el bloque está nuevo y el reloj está parado, empieza la trampa
		if fase_actual == 2 and timer.is_stopped():
			timer.start(1.0) # 1 segundo aguantando antes de empezar a romperse
			
		# Si pisa directamente el hueco cuando ya está roto (-1)
		elif fase_actual == -1:
			matar_jugador()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		jugador_encima = false
		
		# Si el jugador se baja rapidísimo (antes de 1 segundo), detenemos la trampa
		if fase_actual == 2:
			timer.stop()

func _on_timer_timeout() -> void:
	if fase_actual == 2:
		# Pasó 1 segundo pisándolo: Se agrieta (Frame 1)
		fase_actual = 1
		sprite.frame = fase_actual
		# Iniciamos la primera mitad de los 2 segundos de destrucción
		timer.start(1.0) 
		
	elif fase_actual == 1:
		# Pasó 1 segundo más: A punto de romperse (Frame 0)
		fase_actual = 0
		sprite.frame = fase_actual
		# Iniciamos la segunda mitad
		timer.start(1.0)
		
	elif fase_actual == 0:
		# Pasaron los 2 segundos completos de destrucción: ¡Se rompe! (Fase -1)
		fase_actual = -1
		sprite.visible = false # <--- ¡AQUÍ ESTÁ EL VACÍO INVISIBLE!
		timer.start(4.0) # 4 segundos para regenerarse
		
		if jugador_encima:
			matar_jugador()
			
	elif fase_actual == -1:
		# Pasaron los 4 segundos: El bloque se regenera (Vuelve al Frame 2)
		fase_actual = 2
		sprite.frame = fase_actual
		sprite.visible = true 
		
		if jugador_encima:
			timer.start(1.0)

func matar_jugador() -> void:
	var player: Player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player):
		player.defeat(true)
