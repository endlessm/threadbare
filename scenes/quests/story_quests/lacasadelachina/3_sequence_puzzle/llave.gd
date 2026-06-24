extends CharacterBody2D
signal recogida

@export var puntos: Array[Marker2D] = []
@export var intervalo_cambio: float = 3.0
@export var label_mensaje: Label
@export var duracion_mensaje: float = 2.5

var indice_anterior: int = -1
var recogiendo: bool = false
@onready var _timer_cambio: Timer = Timer.new()

func _ready() -> void:
	if not $Hitbox.body_entered.is_connected(_on_hitbox_body_entered):
		$Hitbox.body_entered.connect(_on_hitbox_body_entered)
	print("Hitbox conectado correctamente")

	if puntos.is_empty():
		push_warning("La llave no tiene Marker2D asignados en 'puntos'.")
		return
	_teletransportar_a_punto_aleatorio()
	add_child(_timer_cambio)
	_timer_cambio.wait_time = intervalo_cambio
	_timer_cambio.autostart = true
	_timer_cambio.timeout.connect(_teletransportar_a_punto_aleatorio)
	_timer_cambio.start()

func _physics_process(delta: float) -> void:
	if recogiendo:
		return
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var distancia = global_position.distance_to(player.global_position)
	if distancia < 30:
		recogiendo = true
		_timer_cambio.stop()
		set_physics_process(false)
		visible = false
		recogida.emit()
		await _mostrar_mensaje_felicitacion()
		get_tree().change_scene_to_file("C:/Kiwi/threadbare/scenes/quests/story_quests/lacasadelachina/4_outro/lacasadelachina_outro.tscn")

func _teletransportar_a_punto_aleatorio() -> void:
	if puntos.is_empty():
		return
	if puntos.size() == 1:
		global_position = puntos[0].global_position
		return
	var nuevo_indice: int = indice_anterior
	while nuevo_indice == indice_anterior:
		nuevo_indice = randi() % puntos.size()
	indice_anterior = nuevo_indice
	global_position = puntos[nuevo_indice].global_position

func _on_hitbox_body_entered(body: Node) -> void:
	if body == self:
		return
	print("tocó: ", body.name, " grupos: ", body.get_groups())

func _mostrar_mensaje_felicitacion() -> void:
	if label_mensaje == null:
		push_warning("No se asignó 'label_mensaje' en la Llave; no se puede mostrar el mensaje.")
		return
	label_mensaje.text = "¡Encontraste la llave!"
	label_mensaje.visible = true
	await get_tree().create_timer(duracion_mensaje).timeout
	label_mensaje.visible = false
