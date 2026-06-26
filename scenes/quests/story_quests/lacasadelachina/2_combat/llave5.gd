extends Area2D

# Arrastra aquí varios Marker2D desde el Inspector
@export var puntos_de_aparicion: Array[Marker2D] = []
# Ruta de la siguiente escena
@export var siguiente_escena: String = "res://scenes/quests/story_quests/lacasadelachina/3_sequence_puzzle/lacasadelachina_sequence_puzzle.tscn"
# Tiempo que se muestra el mensaje antes de cambiar de escena
@export var tiempo_mensaje: float = 5.0
@export var mensaje_texto: String = "¡Has conseguido la llave!"

var ya_agarrada: bool = false
@onready var label_mensaje: Label = $CanvasLayer/Label

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	label_mensaje.visible = false

	if puntos_de_aparicion.is_empty():
		push_error("No asignaste ningún Marker2D en el Inspector.")
		return

	# Elige un Marker2D aleatorio del array
	var marker_elegido: Marker2D = puntos_de_aparicion[randi() % puntos_de_aparicion.size()]
	global_position = marker_elegido.global_position

func _on_body_entered(body):
	if ya_agarrada:
		return
	if body is Player:
		ya_agarrada = true
		get_tree().current_scene.llave_recogida_por_jugador()
		mostrar_mensaje_y_cambiar_escena()

func mostrar_mensaje_y_cambiar_escena():
	set_deferred("monitoring", false)
	label_mensaje.text = mensaje_texto
	label_mensaje.visible = true
	label_mensaje.modulate = Color.WHITE
	visible = false
	await get_tree().create_timer(tiempo_mensaje).timeout
	get_tree().change_scene_to_file(siguiente_escena)
