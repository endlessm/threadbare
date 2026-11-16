# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Control

@onready var out_effect_selector: OptionButton = %OutEffectSelector
@onready var in_effect_selector: OptionButton = %InEffectSelector
@onready var test_button: Button = %TestButton
@onready var mid_point_sound: AudioStreamPlayer = %MidPointSound


func _ready() -> void:
	for k: String in Transition.Effect.keys():
		out_effect_selector.add_item(k, Transition.Effect[k])
		in_effect_selector.add_item(k, Transition.Effect[k])

	test_button.pressed.connect(_on_test_button_pressed)


func _on_test_button_pressed() -> void:
	var out_effect := out_effect_selector.selected
	var in_effect := in_effect_selector.selected
	Transitions.do_transition(mid_point_sound.play, out_effect, in_effect)
