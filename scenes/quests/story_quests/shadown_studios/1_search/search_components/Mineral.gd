extends Area2D

# Variables exportadas
@export var collection_sound: AudioStream  # Arrastra un archivo de sonido aquí
@export var points_value: int = 1  # Valor del mineral

# Señal para notificar cuando se recolecta
signal mineral_collected

func _ready():
	# Conectar la señal de detección de cuerpos
	body_entered.connect(_on_body_entered)
	
	# Agregar este nodo al grupo "Mineral"
	add_to_group("Mineral")

func _on_body_entered(body):
	# Verificar si es el jugador
	if body.is_in_group("Player"):
		collect()

func collect():
	# Reproducir sonido si está configurado
	if collection_sound:
		play_collection_sound()
	
	# Emitir señal de recolección
	mineral_collected.emit()
	
	# Eliminar el mineral
	queue_free()

func play_collection_sound():
	# Crear un reproductor temporal para que el sonido termine de reproducirse
	var audio_player = AudioStreamPlayer2D.new()
	audio_player.stream = collection_sound
	audio_player.finished.connect(func(): audio_player.queue_free())
	get_tree().root.add_child(audio_player)
	audio_player.play()
