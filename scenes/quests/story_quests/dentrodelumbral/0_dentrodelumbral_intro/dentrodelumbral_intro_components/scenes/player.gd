# player_controller.gd
extends CharacterBody2D

@export var speed: float = 250.0

func _physics_process(delta: float) -> void:
	# --- Sección de Movimiento (Esta parte no cambia) ---
	var direction: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * speed
	move_and_slide()

	# --- NUEVA SECCIÓN: Mantener al jugador dentro de la pantalla ---
	
	# Obtenemos el tamaño de la ventana del juego.
	#var screen_size = get_viewport_rect().size
	#
	## Usamos clamp() para forzar que la posición del jugador se mantenga
	## entre un mínimo (0,0) y un máximo (el tamaño de la pantalla).
	## Hacemos esto para la coordenada X y la coordenada Y.
	#global_position.x = clamp(global_position.x, 0, screen_size.x)
	#global_position.y = clamp(global_position.y, 0, screen_size.y)
