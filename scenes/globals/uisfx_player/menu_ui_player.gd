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


# Press and release click sound used for buttons
const CLICK = preload("uid://cba2ckeb3gxu1")

# Press click sound used for sliders
const CLICK_SINGLE = preload("uid://pk4mvg05n0uo")

@onready var menu_sfx_player: AudioStreamPlayer = %MenuSFXPlayer



func _enter_tree() -> void:
	get_tree().node_added.connect(_on_node_added)
	



func _on_node_added(node : Node) -> void:
	
	if node is CheckButton and !node.is_connected("toggled", _on_toggle_pressed):
		node.toggled.connect(_on_toggle_pressed)
	
	elif node is Button and !node.is_connected("pressed", _on_button_pressed):
		node.pressed.connect(_on_button_pressed)
		
	elif node is Slider and !node.is_connected("value_changed" ,_on_slider_value_changed):
		node.value_changed.connect(_on_slider_value_changed)
		
	elif node is TabBar and !node.is_connected("tab_clicked" ,_on_slider_value_changed):
		node.tab_clicked.connect(_on_button_pressed)
	

func _on_toggle_pressed(toggled_on: bool) -> void:
	_set_player_sound(CLICK)
	
	if toggled_on:
		menu_sfx_player.pitch_scale = 1.2
	else:
		menu_sfx_player.pitch_scale = 0.7
		
	menu_sfx_player.play()


func _on_button_pressed() -> void:
	_set_player_sound(CLICK)
	menu_sfx_player.pitch_scale = randf_range(0.95, 1.1)
	menu_sfx_player.play()


func _on_slider_value_changed(_value : float) -> void:
	_set_player_sound(CLICK_SINGLE)
	menu_sfx_player.pitch_scale = randf_range(0.95, 1.1)
	menu_sfx_player.play()


func _set_player_sound(sound: AudioStream) -> void:
	if menu_sfx_player.stream != sound:
		menu_sfx_player.stream = sound
	
