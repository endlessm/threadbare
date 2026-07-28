# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@export_multiline var text: String = ""

@onready var interact_area: InteractArea = $InteractArea
@onready var reader: CanvasLayer = $Reader
@onready var book: Control = $Reader/Book
@onready var page_text: RichTextLabel = $Reader/Book/PageText

var _open: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	reader.visible = false
	interact_area.interaction_started.connect(_on_interacted)


func _on_interacted(_player: Player, _from_right: bool) -> void:
	page_text.text = text
	reader.visible = true
	_open = true
	get_tree().paused = true
	book.scale = Vector2(0.85, 0.85)
	var t := reader.create_tween()
	t.tween_property(book, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed(&"interact") or event.is_action_pressed(&"ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()


func _close() -> void:
	_open = false
	reader.visible = false
	get_tree().paused = false
	interact_area.end_interaction()
