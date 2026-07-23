# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

const HOOKABLE_PIN := preload("res://scenes/game_elements/props/hookable_pin/hookable_pin.tscn")

@export var pin_duration: float = 2.5
@export var rise_height: float = 32.0
@export var rise_time: float = 0.45
@export var asleep_color: Color = Color(0.35, 0.38, 0.55)
@export var awake_color: Color = Color(1.0, 1.0, 1.0)

@onready var visual: AnimatedSprite2D = $Visual
@onready var pin_marker: Marker2D = $PinMarker

var _active: bool = false
var _pin: Node2D
var _rest_y: float


func _ready() -> void:
	_rest_y = visual.position.y
	visual.modulate = asleep_color
	if visual.sprite_frames and visual.sprite_frames.has_animation(&"wake"):
		visual.animation = &"wake"
		visual.frame = 0
		visual.stop()


func got_hummed() -> void:
	if _active:
		return
	_awaken()


func _awaken() -> void:
	_active = true

	if visual.sprite_frames and visual.sprite_frames.get_frame_count(&"wake") > 1:
		visual.play(&"wake")
		await visual.animation_finished
	else:
		var tw := create_tween().set_parallel(true)
		tw.tween_property(visual, "position:y", _rest_y - rise_height, rise_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(visual, "modulate", awake_color, rise_time)
		await tw.finished

	visual.modulate = awake_color

	_pin = HOOKABLE_PIN.instantiate()
	add_child(_pin)
	_pin.global_position = pin_marker.global_position
	_pin.modulate.a = 0.0
	create_tween().tween_property(_pin, "modulate:a", 1.0, 0.15)

	await get_tree().create_timer(pin_duration).timeout
	if _active:
		_sleep()


func _sleep() -> void:
	if is_instance_valid(_pin):
		var pin := _pin
		_pin = null
		var t := pin.create_tween()
		t.tween_property(pin, "modulate:a", 0.0, 0.2)
		t.tween_callback(pin.queue_free)

	if visual.sprite_frames and visual.sprite_frames.get_frame_count(&"wake") > 1:
		visual.play_backwards(&"wake")
	else:
		var tw := create_tween().set_parallel(true)
		tw.tween_property(visual, "position:y", _rest_y, rise_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.tween_property(visual, "modulate", asleep_color, rise_time)

	_active = false
