extends Node2D
@onready var animation_player = $AnimationPlayer
@onready var audio_player = $AnimationPlayer/AudioStreamPlayer

func _ready():
	print("=== DIAGNÓSTICO DE AUDIO ===")
	
	# Verificar que el audio_player existe
	if audio_player == null:
		print("ERROR: audio_player es null")
		return
	else:
		print("✓ AudioStreamPlayer2 encontrado")
	
	# Cargar la música
	var audio_stream = load("res://scenes/quests/story_quests/shjourney/9_shjourney_outro_2/Music y efectos/MusicaOutro.mp3")
	if audio_stream == null:
		print("ERROR: No se pudo cargar el archivo de audio")
		return
	else:
		print("✓ Archivo de audio cargado correctamente")
	
	audio_player.stream = audio_stream
	print("✓ Stream asignado al AudioStreamPlayer2")
	
	# Conectar la señal
	animation_player.animation_started.connect(_on_animation_started)
	print("✓ Señal conectada")
	
	# Verificar las animaciones disponibles
	print("Animaciones disponibles:")
	for anim_name in animation_player.get_animation_list():
		print("  - ", anim_name)

func _on_animation_started(anim_name: StringName):
	print("=== ANIMACIÓN INICIADA ===")
	print("Nombre de animación: ", anim_name)
	
	if anim_name == "Tim_position":
		print("✓ Es la animación Tim_position - reproduciendo audio")
		if audio_player != null and audio_player.stream != null:
			audio_player.play()
			print("✓ play() ejecutado")
			print("Volume dB: ", audio_player.volume_db)
			print("Playing: ", audio_player.playing)
		else:
			print("ERROR: audio_player o stream es null")
	else:
		print("⚠ No es la animación Tim_position")
