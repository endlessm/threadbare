# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CanvasLayer
## Libro de historia: pantalla en NEGRO, se abre un libro que cuenta la historia
## página a página, y al terminar (o saltar con Esc) se desvanece y devuelve el
## control. Pausa el juego mientras se muestra.
##
## Sirve para el INTRO (auto_start = true: se abre al cargar la escena) y para el
## FINAL (auto_start = false: queda oculto hasta que algo llame [method start_book],
## p. ej. un Area2D conectada a [method on_player_entered]).

## Títulos (página izquierda del libro). Uno por entrada de [member pages].
## Si falta el título de una página, la página izquierda queda en blanco.
@export var titles: PackedStringArray = []
## Cuerpo de cada página (página derecha del libro). Se permite BBCode ([i], etc.).
@export var pages: PackedStringArray = []
## Duración de los fundidos de apertura/cierre (s).
@export var fade_time: float = 0.7
## Si está activo, el libro se abre solo al cargar la escena (modo intro).
## Si no, queda oculto hasta llamar start_book() (modo final por trigger).
@export var auto_start: bool = true
## (Opcional, modo no-auto) Área que, al entrar el jugador, abre el libro.
@export var trigger_area: Area2D

@onready var black: ColorRect = $Black
@onready var book: Control = $Book
@onready var left_title: Label = $Book/LeftTitle
@onready var right_body: RichTextLabel = $Book/RightBody
@onready var hint: Label = $Hint

var _index: int = 0
var _busy: bool = true
var _started: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if auto_start:
		start_book()
	else:
		visible = false
		if is_instance_valid(trigger_area):
			trigger_area.body_entered.connect(on_player_entered)


## Abre el libro: pausa, muestra la primera página y lo desvanece hacia adentro.
func start_book() -> void:
	if _started:
		return
	_started = true
	visible = true
	get_tree().paused = true
	book.modulate.a = 0.0
	book.scale = Vector2(0.86, 0.86)
	if pages.is_empty():
		_finish()
		return
	_show_page(0)
	var t := create_tween().set_parallel(true)
	t.tween_property(book, "modulate:a", 1.0, fade_time)
	(
		t
		. tween_property(book, "scale", Vector2.ONE, fade_time)
		. set_trans(Tween.TRANS_BACK)
		. set_ease(Tween.EASE_OUT)
	)
	t.chain().tween_callback(_unlock)


## Conéctalo al body_entered de un Area2D para abrir el libro al pasar el jugador.
func on_player_entered(body: Node2D) -> void:
	if not _started and body.is_in_group(&"player"):
		start_book()


func _unlock() -> void:
	_busy = false


func _show_page(i: int) -> void:
	_index = i
	left_title.text = titles[i] if i < titles.size() else ""
	right_body.text = pages[i]
	if i < pages.size() - 1:
		hint.text = "▶  clic / Enter    ·    Esc para saltar"
	else:
		hint.text = "▶  clic / Enter para terminar"


func _unhandled_input(event: InputEvent) -> void:
	if _busy or not _started:
		return
	if event.is_action_pressed(&"ui_cancel"):
		_finish()
		get_viewport().set_input_as_handled()
		return
	var advance := (
		event.is_action_pressed(&"ui_accept")
		or event.is_action_pressed(&"interact")
		or (
			event is InputEventMouseButton
			and (event as InputEventMouseButton).pressed
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT
		)
	)
	if advance:
		_next()
		get_viewport().set_input_as_handled()


func _next() -> void:
	if _index >= pages.size() - 1:
		_finish()
		return
	_busy = true
	var t := create_tween().set_parallel(true)
	t.tween_property(left_title, "modulate:a", 0.0, 0.12)
	t.tween_property(right_body, "modulate:a", 0.0, 0.12)
	t.chain().tween_callback(_advance_page)
	t.tween_property(left_title, "modulate:a", 1.0, 0.14)
	t.tween_property(right_body, "modulate:a", 1.0, 0.14)
	t.chain().tween_callback(_unlock)


func _advance_page() -> void:
	_show_page(_index + 1)


func _finish() -> void:
	_busy = true
	var t := create_tween().set_parallel(true)
	t.tween_property(book, "modulate:a", 0.0, fade_time)
	t.tween_property(black, "color:a", 0.0, fade_time)
	t.chain().tween_callback(_end)


func _end() -> void:
	get_tree().paused = false
	queue_free()
