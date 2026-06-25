extends Node2D

# Solo necesitamos la referencia a tu nodo Cinematic y opcionalmente al jugador
@onready var cinematic_node = $"OnTheGround/Cinematic"
@onready var character = $"OnTheGround/Character"

# Variable para evitar que el diálogo se abra dos veces si das doble clic
var interactuando: bool = false

func _unhandled_input(event: InputEvent) -> void:
	# Detecta si hiciste clic izquierdo
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if interactuando:
			return
			
		var posicion_clic = get_global_mouse_position()
		
		# Coordenadas del hombre de paja (Ajusta el 530 y 460 según tu mapa)
		# El '60' es el radio del área donde puedes hacer clic
		if posicion_clic.distance_to(Vector2(530, 460)) < 60:
			iniciar_dialogo()

func iniciar_dialogo() -> void:
	interactuando = true
	
	# Opcional: Si quieres que el jugador no pueda caminar MIENTRAS habla, 
	# puedes quitar el '#' de la siguiente línea:
	# character.set_physics_process(false)
	
	# Dispara tu diálogo y el cambio de nivel automático
	cinematic_node.start()
