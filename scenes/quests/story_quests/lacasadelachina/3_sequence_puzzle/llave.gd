extends CharacterBody2D

signal recogida

## Lista de Marker2D entre los que se mueve la llave.
## Arrastra aquí los nodos Marker2D desde el editor (en orden no importa, es aleatorio).
@export var puntos: Array[Marker2D] = []

## Cada cuántos segundos la llave se teletransporta a otro punto al azar.
@export var intervalo_cambio: float = 3.0

## Arrastra aquí el Label "MensajeLlave" que muestra el mensaje
## de felicitación al recoger la llave.
@export var label_mensaje: Label

## Cuántos segundos se queda visible el mensaje antes de ocultarse solo.
@export var duracion_mensaje: float = 2.5

var indice_anterior: int = -1

@onready var _timer_cambio: Timer = Timer.new()


func _ready() -> void:
	if puntos.is_empty():
		push_warning("La llave no tiene Marker2D asignados en 'puntos'.")
		return

	_teletransportar_a_punto_aleatorio()

	# Timer que teletransporta la llave cada 'intervalo_cambio' segundos.
	add_child(_timer_cambio)
	_timer_cambio.wait_time = intervalo_cambio
	_timer_cambio.autostart = true
	_timer_cambio.timeout.connect(_teletransportar_a_punto_aleatorio)
	_timer_cambio.start()


func _teletransportar_a_punto_aleatorio() -> void:
	if puntos.is_empty():
		return

	if puntos.size() == 1:
		global_position = puntos[0].global_position
		return

	var nuevo_indice: int = indice_anterior
	# Evita elegir el mismo punto en el que ya estamos, si hay más de uno disponible.
	while nuevo_indice == indice_anterior:
		nuevo_indice = randi() % puntos.size()

	indice_anterior = nuevo_indice
	global_position = puntos[nuevo_indice].global_position


func _on_hitbox_body_entered(body: Node) -> void:
	if body == self:
		return
	if body.is_in_group("player"):
		recogida.emit()
		_mostrar_mensaje_felicitacion()
		set_physics_process(false)
		visible = false


func _mostrar_mensaje_felicitacion() -> void:
	if label_mensaje == null:
		push_warning("No se asignó 'label_mensaje' en la Llave; no se puede mostrar el mensaje.")
		return

	label_mensaje.text = "¡Encontraste la llave!"
	label_mensaje.visible = true

	await get_tree().create_timer(duracion_mensaje).timeout

	label_mensaje.visible = false
