@tool
extends Node

@onready var ui_click_sound: AudioStreamPlayer = %Click
@onready var ui_click_back_sound: AudioStreamPlayer = %ClickBack
@onready var ui_click_toggle_sound: AudioStreamPlayer = %ClickToggle

func play_ui_click():
	ui_click_sound.play()

func play_ui_click_back():
	ui_click_back_sound.play()
	
func play_ui_click_toggle():
	ui_click_toggle_sound.play()
