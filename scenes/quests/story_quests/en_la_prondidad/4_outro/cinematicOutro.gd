# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Cinematic
@export var slider: TextureRect
@export var slider_frames: SpriteFrames
@export var slider_animation: StringName = &"default"

var _slider_frame: int = 0


func _ready() -> void:
	# Inicializamos el primer frame de la imagen
	_show_slider_frame(0)
	
	# Conectamos la señal de forma segura comprobando que no esté conectada ya
	if DialogueManager.has_signal("got_dialogue"):
		if not DialogueManager.got_dialogue.is_connected(_on_dialogue_advanced):
			DialogueManager.got_dialogue.connect(_on_dialogue_advanced)
	
	# Llamamos al _ready del padre para que ejecute su 'start()' original sin alterar nada
	super._ready()


func _exit_tree() -> void:
	# Limpieza crucial: desconectamos al salir de la escena para no romper futuros diálogos del juego
	if DialogueManager.has_signal("got_dialogue"):
		if DialogueManager.got_dialogue.is_connected(_on_dialogue_advanced):
			DialogueManager.got_dialogue.disconnect(_on_dialogue_advanced)


func advance_frame() -> void:
	_show_slider_frame(_slider_frame + 1)


func _show_slider_frame(index: int) -> void:
	if (
		not slider
		or not slider_frames
		or not slider_frames.has_animation(slider_animation)
		or index < 0
		or index >= slider_frames.get_frame_count(slider_animation)
	):
		return

	_slider_frame = index
	slider.texture = slider_frames.get_frame_texture(slider_animation, index)


func _on_dialogue_advanced(_line) -> void:
	advance_frame()
