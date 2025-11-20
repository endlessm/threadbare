extends AudioStreamPlayer

# Variable para controlar el ritmo de los pasos
var can_play_step: bool = true

func _ready() -> void:
	# Configuración inicial importante
	autoplay = false
	stop()
	print($".")

# Función para reproducir el sonido de paso
func play_step() -> void:
	if can_play_step and not playing:
		play()
		can_play_step = false
		# Esperar antes del siguiente paso
		await get_tree().create_timer(0.3).timeout
		can_play_step = true
		
		
