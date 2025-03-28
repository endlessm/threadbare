class_name Transition
extends CanvasLayer

enum Effect { FADE, LEFT_TO_RIGHT_WIPE, RIGHT_TO_LEFT_WIPE, RADIAL }

const FADE_TEXTURE: Texture = preload("res://scenes/transitions/Fade.png")
const LEFT_TO_RIGHT_WIPE_TEXTURE: Texture = preload("res://scenes/transitions/LeftToRightWipe.png")
const RADIAL_TEXTURE: Texture = preload("res://scenes/transitions/Radial.png")
const RIGHT_TO_LEFT_WIPE_TEXTURE: Texture = preload("res://scenes/transitions/RightToLeftWipe.png")

var _current_tween: Tween

@onready var transition_mask: ColorRect = $TransitionMask


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


func leave_scene(
	_transition_effect: Effect = Effect.FADE,
	duration: float = 1.0,
	easing: Tween.EaseType = Tween.EaseType.EASE_IN,
	transition_type: Tween.TransitionType = Tween.TransitionType.TRANS_QUAD
) -> void:
	visible = true
	await _do_tween(0.0, _transition_effect, duration, easing, transition_type)
	visible = false


func introduce_scene(
	_transition_effect: Effect = Effect.FADE,
	duration: float = 1.0,
	easing: Tween.EaseType = Tween.EaseType.EASE_IN,
	transition_type: Tween.TransitionType = Tween.TransitionType.TRANS_QUAD
) -> void:
	visible = true
	await _do_tween(1.0, _transition_effect, duration, easing, transition_type)
	visible = false
