# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Control

signal back

## Auto-scroll speed.
var _auto_scroll_speed: float = 50.0
## Manual scroll speed (arrows/joystick).
var _manual_scroll_speed: float = 300.0
## Delay before starting auto-scroll (in seconds).
var _start_delay: float = 1.0
## Background animation name.
var _animation_name: String = "sketches"

var _is_auto_scrolling: bool = false
var _current_scroll_pos: float = 0.0

@onready var back_button: Button = %BackButton
@onready var background_anim_player: AnimationPlayer = %AnimationPlayer
@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var scroll_content: VBoxContainer = %ScrollContent


func _ready() -> void:
	if not visibility_changed.is_connected(_on_visibility_changed):
		visibility_changed.connect(_on_visibility_changed)

	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER

	set_process(false)
	_on_visibility_changed()


func _process(delta: float) -> void:
	var input_axis: float = Input.get_axis("move_up", "move_down")
	if is_zero_approx(input_axis):
		input_axis = Input.get_axis("ui_up", "ui_down")

	if not is_zero_approx(input_axis):
		_is_auto_scrolling = false
		_current_scroll_pos += input_axis * _manual_scroll_speed * delta
		_current_scroll_pos = clampf(_current_scroll_pos, 0.0, scroll_content.size.y)
	elif _is_auto_scrolling:
		_current_scroll_pos += _auto_scroll_speed * delta
		_current_scroll_pos = clampf(_current_scroll_pos, 0.0, scroll_content.size.y)

	scroll_container.scroll_vertical = int(_current_scroll_pos)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if (
		event.is_action_pressed("ui_up")
		or event.is_action_pressed("ui_down")
		or event.is_action_pressed("move_up")
		or event.is_action_pressed("move_down")
	):
		get_viewport().set_input_as_handled()


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
			_current_scroll_pos = scroll_container.scroll_vertical


func start_credits_sequence() -> void:
	background_anim_player.play(_animation_name)

	_current_scroll_pos = 0.0
	scroll_container.scroll_vertical = 0
	_is_auto_scrolling = false
	set_process(true)

	await get_tree().create_timer(_start_delay).timeout

	if visible and scroll_container.scroll_vertical == 0:
		_is_auto_scrolling = true


func _on_rich_text_label_meta_clicked(meta: Variant) -> void:
	OS.shell_open(str(meta))


func _on_visibility_changed() -> void:
	if visible:
		back_button.grab_focus()
		start_credits_sequence()
	else:
		_stop_credits_sequence()


func _on_back_button_pressed() -> void:
	back.emit()


func _stop_credits_sequence() -> void:
	_is_auto_scrolling = false
	set_process(false)
	background_anim_player.stop()
