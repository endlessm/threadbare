# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Control

signal back

## Auto-scroll speed.
@export var auto_scroll_speed: float = 50.0
## Manual scroll speed (arrows/joystick).
@export var manual_scroll_speed: float = 500.0
## Delay before starting auto-scroll (in seconds).
@export var start_delay: float = 1.0
## Background animation name.
@export var animation_name: String = "sketches"

var _is_auto_scrolling: bool = false
var _current_scroll_pos: float = 0.0

@onready var back_button: Button = %BackButton
@onready var background_anim_player: AnimationPlayer = %AnimationPlayer
@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var scroll_content: VBoxContainer = %ScrollContent


func _ready() -> void:
	if not visibility_changed.is_connected(_on_visibility_changed):
		visibility_changed.connect(_on_visibility_changed)

	if scroll_container:
		scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER

	set_process(false)
	_on_visibility_changed()


func _process(delta: float) -> void:
	if not scroll_container:
		return

	var input_axis: float = Input.get_axis("move_up", "move_down")
	if is_zero_approx(input_axis):
		input_axis = Input.get_axis("ui_up", "ui_down")

	if not is_zero_approx(input_axis):
		_is_auto_scrolling = false
		_current_scroll_pos += input_axis * manual_scroll_speed * delta
	elif _is_auto_scrolling:
		_current_scroll_pos += auto_scroll_speed * delta

	scroll_container.scroll_vertical = int(_current_scroll_pos)

	if _current_scroll_pos >= scroll_content.size.y:
		pass


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back_button_pressed()
		return

	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			_is_auto_scrolling = false
			if scroll_container:
				_current_scroll_pos = scroll_container.scroll_vertical

	if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
		get_viewport().set_input_as_handled()


func start_credits_sequence() -> void:
	if background_anim_player and background_anim_player.has_animation(animation_name):
		background_anim_player.play(animation_name)
	elif background_anim_player:
		push_warning("Animation not found: " + animation_name)

	if scroll_container:
		_current_scroll_pos = 0.0
		scroll_container.scroll_vertical = 0
		_is_auto_scrolling = false
		set_process(true)

		await get_tree().create_timer(start_delay).timeout

		if visible and scroll_container.scroll_vertical == 0:
			_is_auto_scrolling = true


func _on_rich_text_label_meta_clicked(meta: Variant) -> void:
	OS.shell_open(str(meta))


func _on_visibility_changed() -> void:
	if visible:
		if back_button:
			back_button.grab_focus()
		start_credits_sequence()
	else:
		_stop_credits_sequence()


func _on_back_button_pressed() -> void:
	back.emit()


func _stop_credits_sequence() -> void:
	_is_auto_scrolling = false
	set_process(false)
	if background_anim_player:
		background_anim_player.stop()
