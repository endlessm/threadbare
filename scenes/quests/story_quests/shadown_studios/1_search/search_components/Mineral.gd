extends Area2D

# Variables exportadas
@export var collection_sound: AudioStream
@export var points_value: int = 1

# Señal para notificar cuando se recolecta
signal mineral_collected

# Referencia al InteractArea
@onready var interact_area: InteractArea = $InteractArea
var player_nearby: Player = null
var can_interact: bool = false

func _ready():
	# Agregar al grupo "Mineral"
	add_to_group("Mineral")
	
	# Conectar señales del InteractArea
	if interact_area:
		interact_area.interaction_started.connect(_on_interaction_started)
		interact_area.interaction_ended.connect(_on_interaction_ended)
	
	# Detectar cuando el jugador está cerca
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta):
	# Verificar si el jugador presiona espacio mientras está cerca
	if can_interact and player_nearby and Input.is_action_just_pressed("ui_accept"):
		collect()

func _on_body_entered(body):
	if body is Player:
		player_nearby = body
		can_interact = true

func _on_body_exited(body):
	if body is Player:
		player_nearby = null
		can_interact = false

func _on_interaction_started(player: Player, _from_right: bool):
	player_nearby = player
	can_interact = true

func _on_interaction_ended():
	can_interact = false

func collect():
	# Reproducir sonido si está configurado
	if collection_sound:
		play_collection_sound()
	
	# Emitir señal de recolección
	mineral_collected.emit()
	
	print("Mineral recolectado!")
	
	# Eliminar el mineral
	queue_free()

func play_collection_sound():
	var audio_player = AudioStreamPlayer2D.new()
	audio_player.stream = collection_sound
	audio_player.finished.connect(func(): audio_player.queue_free())
	get_tree().root.add_child(audio_player)
	audio_player.play()
