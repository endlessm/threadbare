# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node
## Global Menu UI player
##
## This singleton node handles playing UI SFX when interacting with any button
## in game. It runs once when entering the tree and connects the respective
## "pressed" signal with a function that reproduces a sound
##
## The sound reproduced depends on the type of interactable clicked

@onready var slider_sfx_player: AudioStreamPlayer = %SliderSFXPlayer
@onready var button_sfx_player: AudioStreamPlayer = $ButtonSFXPlayer
@onready var toggle_on_sfx_player: AudioStreamPlayer = $ToggleOnSFXPlayer
@onready var toggle_off_sfx_player: AudioStreamPlayer = $ToggleOffSFXPlayer


func _enter_tree() -> void:
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if node is CheckButton and !node.is_connected("toggled", _on_toggle_pressed):
		node.toggled.connect(_on_toggle_pressed)

	elif node is Button and !node.is_connected("pressed", _on_button_pressed):
		node.pressed.connect(_on_button_pressed)

	elif node is Slider and !node.is_connected("value_changed", _on_slider_value_changed):
		node.value_changed.connect(_on_slider_value_changed)

	elif node is TabBar and !node.is_connected("tab_clicked", _on_slider_value_changed):
		node.tab_clicked.connect(_on_tab_clicked)


func _on_toggle_pressed(toggled_on: bool) -> void:
	if toggled_on:
		toggle_on_sfx_player.play()
	else:
		toggle_off_sfx_player.play()


func _on_button_pressed() -> void:
	button_sfx_player.play()


func _on_slider_value_changed(_value: float) -> void:
	slider_sfx_player.play()


func _on_tab_clicked(_tab: int) -> void:
	button_sfx_player.play()
