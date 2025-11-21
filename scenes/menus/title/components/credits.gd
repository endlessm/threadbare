# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Control

signal back

## Speed at which the credits scroll upward.
@export var scroll_speed: float = 50.0
## Name of the background animation to play.
@export var animation_name: String = "sketches"

var _is_scrolling: bool = false
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
	if _is_scrolling and scroll_container:
		_current_scroll_pos += scroll_speed * delta
		scroll_container.scroll_vertical = int(_current_scroll_pos)

		if _current_scroll_pos >= scroll_content.size.y:
			_on_credits_finished()


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_accept"):
		scroll_speed = 150.0
	elif visible and event.is_action_released("ui_accept"):
		scroll_speed = 50.0


## Start the credits sequence with background animation and scrolling.
func start_credits_sequence() -> void:
	if background_anim_player and background_anim_player.has_animation(animation_name):
		background_anim_player.play(animation_name)
	elif background_anim_player:
		push_warning("Animation not found: " + animation_name)

	if scroll_container:
		_current_scroll_pos = 0.0
		scroll_container.scroll_vertical = 0
		_is_scrolling = true
		set_process(true)


## Open links in the user's default browser.
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
	_is_scrolling = false
	set_process(false)
	if background_anim_player:
		background_anim_player.stop()


func _on_credits_finished() -> void:
	print("Credits finished")
	_is_scrolling = false
