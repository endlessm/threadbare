# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name Transition
extends CanvasLayer

## Emitted when a transition to a new scene starts
signal started
## Emitted when a transition to a new scene finishes
signal finished

enum Effect {
	FADE, LEFT_TO_RIGHT_WIPE, RIGHT_TO_LEFT_WIPE, RADIAL, TOP_TO_BOTTOM_WIPE, BOTTOM_TO_TOP_WIPE
}

const FADE_TEXTURE: Texture = preload("uid://cpvc4xmg7at7r")
const LEFT_TO_RIGHT_WIPE_TEXTURE: Texture = preload("uid://wxf47acry7qc")
const RADIAL_TEXTURE: Texture = preload("uid://dcwmaoqgu5t84")
const RIGHT_TO_LEFT_WIPE_TEXTURE: Texture = preload("uid://b4lvabnu81em4")
const TOP_TO_BOTTOM_WIPE_TEXTURE: Texture = preload("uid://o26lx6drd3p1")
const BOTTOM_TO_TOP_WIPE_TEXTURE: Texture = preload("uid://dv8a5iybchwot")

var _current_tween: Tween

@onready var transition_mask: ColorRect = $TransitionMask


func _input(_event: InputEvent) -> void:
	if visible:
		get_viewport().set_input_as_handled()


func _do_tween(
	final_val: float,
	transition_effect: Effect,
	duration: float,
	easing: Tween.EaseType,
	transition_type: Tween.TransitionType
) -> void:
	match transition_effect:
		Effect.FADE:
			transition_mask.material.set("shader_parameter/mask", FADE_TEXTURE)
		Effect.LEFT_TO_RIGHT_WIPE:
			transition_mask.material.set("shader_parameter/mask", LEFT_TO_RIGHT_WIPE_TEXTURE)
		Effect.RIGHT_TO_LEFT_WIPE:
			transition_mask.material.set("shader_parameter/mask", RIGHT_TO_LEFT_WIPE_TEXTURE)
		Effect.RADIAL:
			transition_mask.material.set("shader_parameter/mask", RADIAL_TEXTURE)
		Effect.TOP_TO_BOTTOM_WIPE:
			transition_mask.material.set("shader_parameter/mask", TOP_TO_BOTTOM_WIPE_TEXTURE)
		Effect.BOTTOM_TO_TOP_WIPE:
			transition_mask.material.set("shader_parameter/mask", BOTTOM_TO_TOP_WIPE_TEXTURE)
	if is_instance_valid(_current_tween) and _current_tween.is_running():
		_current_tween.finished.emit()
		_current_tween.kill()
	_current_tween = create_tween()
	(
		_current_tween
		. tween_property($TransitionMask.material, "shader_parameter/cutoff", final_val, duration)
		. set_ease(easing)
		. set_trans(transition_type)
	)

	await _current_tween.finished


func _leave_scene(
	_transition_effect: Effect = Effect.FADE,
	duration: float = 1.0,
	easing: Tween.EaseType = Tween.EaseType.EASE_OUT,
	transition_type: Tween.TransitionType = Tween.TransitionType.TRANS_QUAD
) -> void:
	await _do_tween(0.0, _transition_effect, duration, easing, transition_type)


func _introduce_scene(
	_transition_effect: Effect = Effect.FADE,
	duration: float = 1.0,
	easing: Tween.EaseType = Tween.EaseType.EASE_IN,
	transition_type: Tween.TransitionType = Tween.TransitionType.TRANS_QUAD
) -> void:
	await _do_tween(1.0, _transition_effect, duration, easing, transition_type)


func do_transition(
	in_between: Callable,
	out_transition: Transition.Effect = Transition.Effect.FADE,
	in_transition: Transition.Effect = Transition.Effect.FADE,
) -> void:
	visible = true
	started.emit()
	await _leave_scene(out_transition)
	await in_between.call()
	await _introduce_scene(in_transition)
	visible = false
	finished.emit()


## Returns true if a transition is currently running. Monitor [signal started]
## and [signal finished] for changes.
func is_running() -> bool:
	return visible
