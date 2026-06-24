extends CharacterBody2D

@export_file("*.tscn") var ruta_player_real: String 

@export var cambiar_al_inicio: bool = false

func _ready() -> void:
	if cambiar_al_inicio:
		convertir_a_jugador()

func convertir_a_jugador() -> void:
	if ruta_player_real == "":
		print("¡Error! No has asignado la ruta del Player jugable en el Inspector.")
		return
		
	var escena_player = load(ruta_player_real)
	
	if escena_player:
		var nuevo_player = escena_player.instantiate()
		nuevo_player.global_position = global_position
		
		get_parent().add_child(nuevo_player)
		
		# Buscamos el nodo Camera2D dentro del nuevo jugador real
		if nuevo_player.has_node("Camera2D"):
			var nueva_camara: Camera2D = nuevo_player.get_node("Camera2D")
			# Forzamos a Godot a usar esta nueva cámara
			nueva_camara.make_current()
			
			nueva_camara.reset_smoothing()
		
		queue_free()
