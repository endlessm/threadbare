extends Area2D

# Posiciones fijas donde puede aparecer la llave (convertidas de coordenadas de tile, tile_size = 64)
var posiciones: Array = [
	Vector2(-256, 640),   # tile (-4, 10)  -- antes (-6, 12), movida 2 tiles hacia adentro
	Vector2(1152, 640),   # tile (18, 10)  -- antes (20, 12), movida 2 tiles hacia adentro
	Vector2(1152, -128),  # tile (18, -2)  -- antes (20, -4), movida 2 tiles hacia adentro
	Vector2(-256, -128),  # tile (-4, -2)  -- antes (-6, -4), movida 2 tiles hacia adentro
	Vector2(-128, 192),   # tile (-2, 3)
	Vector2(768, 256),    # tile (12, 4)
	Vector2(1216, 256),   # tile (19, 4)
	Vector2(448, 384),    # tile (7, 6)
]

# Tiempo en segundos entre cada teletransporte
@export var tiempo_entre_teletransportes: float = 3.0

# Ruta de la escena a la que se cambia cuando el jugador agarra la llave
@export var siguiente_escena: String = "res://scenes/quests/story_quests/lacasadelachina/3_sequence_puzzle/lacasadelachina_sequence_puzzle.tscn"

# Tiempo que se muestra el mensaje antes de cambiar de escena
@export var tiempo_mensaje: float = 5.0

@export var mensaje_texto: String = "¡Has conseguido la llave!"

var timer: Timer
var ya_agarrada: bool = false

@onready var label_mensaje: Label = $CanvasLayer/Label


func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

	label_mensaje.visible = false

	# Colocamos la llave en una posición random al iniciar
	global_position = posiciones[randi() % posiciones.size()]

	# Timer para el teletransporte automático
	if timer == null:
		timer = Timer.new()
		timer.wait_time = tiempo_entre_teletransportes
		timer.autostart = true
		timer.one_shot = false
		add_child(timer)
		timer.connect("timeout", Callable(self, "_on_timer_timeout"))


func _on_timer_timeout():
	if ya_agarrada:
		return
	teletransportar_a_posicion_random()


func teletransportar_a_posicion_random():
	var nueva_pos = posiciones[randi() % posiciones.size()]
	if posiciones.size() > 1:
		while nueva_pos == global_position:
			nueva_pos = posiciones[randi() % posiciones.size()]

	global_position = nueva_pos


func _on_body_entered(body):
	if ya_agarrada:
		return

	if body is Player:
		ya_agarrada = true
		timer.stop()

		get_node("/root/LacasadelachinaCombat").llave_recogida_por_jugador()

		mostrar_mensaje_y_cambiar_escena()


func mostrar_mensaje_y_cambiar_escena():
	set_deferred("monitoring", false)

	# Mostramos el mensaje ANTES de ocultar la llave,
	# para evitar que la visibilidad del padre afecte al CanvasLayer/Label.
	label_mensaje.text = mensaje_texto
	label_mensaje.visible = true
	label_mensaje.modulate = Color(1, 1, 1, 1)

	print("LABEL DEBUG -> visible: ", label_mensaje.visible, " | text: ", label_mensaje.text, " | global_position: ", label_mensaje.global_position, " | modulate: ", label_mensaje.modulate)
	print("CANVASLAYER DEBUG -> layer: ", $CanvasLayer.layer, " | visible: ", $CanvasLayer.visible)

	visible = false

	await get_tree().create_timer(tiempo_mensaje).timeout

	get_tree().change_scene_to_file(siguiente_escena)
