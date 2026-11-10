# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends PanelContainer
## Globo de pensamiento que sigue a un personaje y escribe el texto poco a poco.

const VELOCIDAD_DE_SEGUIMIENTO: float = 10.0
const DESPLAZAMIENTO_INICIAL := Vector2(0, 20)
const ESCALA_INICIAL := Vector2(0.5, 0.5)
const DURACION_APARICION: float = 1.2
const DURACION_FUNDIDO_DE_ENTRADA: float = 0.8
const SEGUNDOS_POR_LETRA: float = 0.04
const MAXIMO_TIEMPO_DE_ESCRITURA: float = 3.5
const PAUSA_DESPUES_DE_ESCRIBIR: float = 2.5
const DURACION_DESAPARICION: float = 1.5
const DURACION_FUNDIDO_DE_SALIDA: float = 1.2
const DISTANCIA_CABEZA_POR_DEFECTO: float = 65.0
const GRUPO_JUGADOR: StringName = &"player"

var jugador_objetivo: Node2D
var offset_flotante: Vector2 = Vector2.ZERO
var distancia_cabeza: float = DISTANCIA_CABEZA_POR_DEFECTO

var _animacion: Tween

@onready var label: Label = $Label
@onready var timer: Timer = $Label/Timer


func _ready() -> void:
	hide()
	jugador_objetivo = get_tree().get_first_node_in_group(GRUPO_JUGADOR)

	if not timer.timeout.is_connected(_on_timer_timeout):
		timer.timeout.connect(_on_timer_timeout)


func _process(delta: float) -> void:
	if visible and is_instance_valid(jugador_objetivo):
		position = position.lerp(_posicion_sobre_el_objetivo(), VELOCIDAD_DE_SEGUIMIENTO * delta)


func mostrar_pensamiento(nuevo_texto: String) -> void:
	_detener_animacion()

	label.text = nuevo_texto
	label.visible_ratio = 0.0
	offset_flotante = DESPLAZAMIENTO_INICIAL

	# sin reset_size el globo conserva el tamaño del texto anterior
	reset_size()

	if is_instance_valid(jugador_objetivo):
		position = _posicion_sobre_el_objetivo()

	pivot_offset = size / 2.0
	scale = ESCALA_INICIAL
	modulate.a = 0.0
	show()

	_animacion = create_tween().set_parallel(true)
	(
		_animacion
		. tween_property(self, "offset_flotante:y", 0.0, DURACION_APARICION)
		. set_trans(Tween.TRANS_BACK)
		. set_ease(Tween.EASE_OUT)
	)
	(
		_animacion
		. tween_property(self, "scale", Vector2.ONE, DURACION_APARICION)
		. set_trans(Tween.TRANS_ELASTIC)
		. set_ease(Tween.EASE_OUT)
	)
	_animacion.tween_property(self, "modulate:a", 1.0, DURACION_FUNDIDO_DE_ENTRADA)

	var tiempo_escritura := minf(
		nuevo_texto.length() * SEGUNDOS_POR_LETRA, MAXIMO_TIEMPO_DE_ESCRITURA
	)
	_animacion.tween_property(label, "visible_ratio", 1.0, tiempo_escritura)

	timer.start(tiempo_escritura + PAUSA_DESPUES_DE_ESCRIBIR)


func _detener_animacion() -> void:
	if _animacion and _animacion.is_valid():
		_animacion.kill()


func _posicion_sobre_el_objetivo() -> Vector2:
	var posicion_en_pantalla := jugador_objetivo.get_global_transform_with_canvas().origin
	return posicion_en_pantalla - Vector2(size.x / 2.0, size.y + distancia_cabeza) + offset_flotante


func _on_timer_timeout() -> void:
	_detener_animacion()

	pivot_offset = size / 2.0

	_animacion = create_tween().set_parallel(true)
	(
		_animacion
		. tween_property(self, "scale", Vector2.ZERO, DURACION_DESAPARICION)
		. set_trans(Tween.TRANS_SINE)
		. set_ease(Tween.EASE_IN_OUT)
	)
	_animacion.tween_property(self, "modulate:a", 0.0, DURACION_FUNDIDO_DE_SALIDA)

	_animacion.chain().tween_callback(hide)
