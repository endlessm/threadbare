extends Area2D

# Arrastra aquí, desde el árbol de escena, los nodos Marker2D que tengas en
# esta escena. Esto reemplaza el array "posiciones" que estaba hardcodeado
# en código: ahora se asigna visualmente desde el Inspector, y puedes mover
# cada marcador en el editor 2D para ver exactamente dónde va a aparecer la llave.
@export var puntos_de_aparicion: Array[Marker2D] = []

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

	if puntos_de_aparicion.is_empty():
		push_warning("¡No asignaste ningún Marker2D en 'Puntos De Aparicion' desde el Inspector!")
		return

	print("TOTAL DE MARCADORES ASIGNADOS: ", puntos_de_aparicion.size())

	# Colocamos la llave en la posición de uno de los marcadores al iniciar
	global_position = puntos_de_aparicion[randi() % puntos_de_aparicion.size()].global_position
	print("LLAVE FINAL POSITION: ", global_position, " | VISIBLE: ", visible, " | MODULATE: ", modulate)

	# IMPORTANTE: este bloque crea el Timer para el teletransporte automático.
	# Sin esto, "timer" queda en null y _on_body_entered() crashea al llamar
	# timer.stop() con "Cannot call method 'stop' on a null value".
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
	if puntos_de_aparicion.is_empty():
		return

	var nuevo_marcador: Marker2D = puntos_de_aparicion[randi() % puntos_de_aparicion.size()]

	if puntos_de_aparicion.size() > 1:
		while nuevo_marcador.global_position == global_position:
			nuevo_marcador = puntos_de_aparicion[randi() % puntos_de_aparicion.size()]

	global_position = nuevo_marcador.global_position
	print("LLAVE TELETRANSPORTADA A: ", nuevo_marcador.name, " | POSICION: ", global_position)


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
