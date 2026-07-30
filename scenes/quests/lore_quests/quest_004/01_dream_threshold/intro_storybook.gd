# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CanvasLayer

@export
var titles: PackedStringArray = ["The Last Petal", "The Weaver Wakes", "Before the Petal Falls"]

@export var pages: PackedStringArray = [
	(
		"Long ago, every dream was woven on a single Loom, and at its heart grew a flower "
		+ "— the [i]Stellaria[/i] — whose petals held all we remember, imagine and feel."
	),
	"You are the [i]Storyweaver[/i], called from sleep to gather what was lost.",
	"Through golden meadows, a keeper's garden, a forgetting forest and a fleeing night...",
]

@export var pages_right: PackedStringArray = [
	(
		"Then the Void crept in, thread by thread, and the petals fell, one by one, until "
		+ "the meadow itself grew quiet and grey.\n\nOnly the last petal still clings — "
		+ "trembling, waiting for someone to answer its call."
	),
	(
		"Three threads remain — [i]Memory[/i], [i]Imagination[/i] and [i]Spirit[/i] — "
		+ "scattered across the dreaming meadow.\n\nHum to the old stones and they will "
		+ "rise to carry you; pull each thread back toward the Loom before it unravels for good."
	),
	(
		"Find the three threads. Bring them to Noria's Loom.\n\nMake the Stellaria bloom "
		+ "— before the last petal lets go, and the dream forgets itself forever."
	),
]
@export var fade_time: float = 0.7
@export var auto_start: bool = true
@export var trigger_area: Area2D

var _index: int = 0
var _busy: bool = true
var _started: bool = false

@onready var black: ColorRect = $Black
@onready var book: Control = $Book
@onready var book_art: AnimatedTextureRect = $Book
@onready var left_title: Label = $Book/TitleBox/LeftTitle
@onready var left_body: RichTextLabel = $Book/LeftBody
@onready var right_body: RichTextLabel = $Book/RightBody
@onready var hint: Label = $Hint


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if auto_start:
		start_book()
	else:
		visible = false
		if is_instance_valid(trigger_area):
			trigger_area.body_entered.connect(on_player_entered)


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
	t.tween_property(book, "scale", Vector2.ONE, fade_time).set_trans(Tween.TRANS_BACK).set_ease(
		Tween.EASE_OUT
	)
	t.chain().tween_callback(_unlock)


func on_player_entered(body: Node2D) -> void:
	if not _started and body.is_in_group(&"player"):
		start_book()


func _unlock() -> void:
	_busy = false


func _show_page(i: int) -> void:
	_index = i
	left_title.text = titles[i] if i < titles.size() else ""
	left_body.text = pages[i]
	right_body.text = pages_right[i] if i < pages_right.size() else ""
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
	_play_page_flip()
	var t := create_tween().set_parallel(true)
	t.tween_property(left_title, "modulate:a", 0.0, 0.12)
	t.tween_property(left_body, "modulate:a", 0.0, 0.12)
	t.tween_property(right_body, "modulate:a", 0.0, 0.12)
	t.chain().tween_callback(_advance_page)
	t.tween_property(left_title, "modulate:a", 1.0, 0.14)
	t.tween_property(left_body, "modulate:a", 1.0, 0.14)
	t.tween_property(right_body, "modulate:a", 1.0, 0.14)
	t.chain().tween_callback(_unlock)


func _advance_page() -> void:
	_show_page(_index + 1)


## Reuses the shared storybook page-turn art (see scenes/menus/storybook/).
func _play_page_flip() -> void:
	book_art.animation_name = &"book_right"
	var frames := book_art.sprite_frames
	var duration := (
		frames.get_frame_count(&"book_right") / frames.get_animation_speed(&"book_right")
	)
	get_tree().create_timer(duration).timeout.connect(_on_page_flip_finished)


func _on_page_flip_finished() -> void:
	book_art.animation_name = &"idle"


func _finish() -> void:
	_busy = true
	var t := create_tween().set_parallel(true)
	t.tween_property(book, "modulate:a", 0.0, fade_time)
	t.tween_property(black, "color:a", 0.0, fade_time)
	t.chain().tween_callback(_end)


func _end() -> void:
	get_tree().paused = false
	queue_free()
