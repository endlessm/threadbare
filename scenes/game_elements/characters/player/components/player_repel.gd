# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name PlayerRepel
extends Node2D

signal repelling_changed(repelling: bool)

const REPEL_ANTICIPATION_TIME: float = 0.3

@export var player_controlled: bool = true
@export var input_action: StringName = &"repel"

@export var max_duration: float = 0.8  
@export var cooldown: float = 1.5      

# --- NUEVO: VARIABLE PARA EL SONIDO DE ERROR ---
@export var error_sound: AudioStream
# -----------------------------------------------

@export var repelling: bool = false:
	set = _set_repelling

var _is_on_cooldown: bool = false
var _active_time: float = 0.0

@onready var air_stream: Area2D = %AirStream
@onready var repel_animation: AnimationPlayer = %RepelAnimation


func _process(delta: float) -> void:
	if repelling:
		_active_time += delta
		if _active_time >= max_duration:
			_trigger_cooldown()


func _set_repelling(new_repelling: bool) -> void:
	repelling = new_repelling
	if not is_node_ready():
		return
	repelling_changed.emit(repelling)
	if repelling:
		_animate()


func _unhandled_input(_event: InputEvent) -> void:
	if not player_controlled:
		return
		
	if Input.is_action_just_pressed(input_action):
		if not _is_on_cooldown:
			_active_time = 0.0 
			repelling = true
		else:
			# Si está en cooldown y presiona, mostramos la advertencia
			_show_cooldown_warning()
			
	elif Input.is_action_just_released(input_action):
		if repelling:
			_trigger_cooldown()


# --- NUEVA FUNCIÓN: TEXTO FLOTANTE Y SONIDO ---
func _show_cooldown_warning() -> void:
	# 1. Reproducir sonido de error (si le asignaste uno en el Inspector)
	if error_sound:
		var audio = AudioStreamPlayer2D.new()
		audio.stream = error_sound
		add_child(audio)
		audio.play()
		audio.finished.connect(audio.queue_free) # Se autodestruye al terminar
	
	# 2. Crear texto flotante ("¡Aún no!")
	var label = Label.new()
	label.text = "¡Aún no!"
	label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2)) # Color Rojo
	
	# Opcional: ponerle un contorno negro para que se lea mejor
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	
	# Posicionarlo un poco arriba y a la izquierda de Floresta
	label.position = Vector2(-25, -60)
	add_child(label)
	
	# 3. Animar el texto (que suba y se desvanezca)
	var tween = create_tween()
	tween.set_parallel(true) # Para animar posición y transparencia al mismo tiempo
	tween.tween_property(label, "position", label.position + Vector2(0, -40), 0.5)
	tween.tween_property(label, "modulate:a", 0.0, 0.5) # Modifica la transparencia (Alfa) a 0
	
	# Cuando termine la animación, eliminamos el texto de la memoria
	tween.chain().tween_callback(label.queue_free)
# ----------------------------------------------


func _trigger_cooldown() -> void:
	repelling = false
	_is_on_cooldown = true
	
	var sprite: AnimatedSprite2D = owner.get_node_or_null("%PlayerSprite")
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(0.8, 0.4, 0.4, 0.8), 0.2)
	
	await get_tree().create_timer(cooldown).timeout
	
	_is_on_cooldown = false
	
	if sprite:
		sprite.modulate = Color(2.0, 2.0, 2.0, 1.0) 
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)


func repel_once() -> void:
	if not _is_on_cooldown:
		repelling = true
		repelling = false


func _on_air_stream_body_entered(body: Node2D) -> void:
	if body.has_method("got_repelled"):
		var direction := global_position.direction_to(body.global_position)
		body.got_repelled(direction)


func _animate() -> void:
	if repel_animation.current_animation == &"repel":
		return
	repel_animation.play(&"repel")
	repel_animation.seek(REPEL_ANTICIPATION_TIME, false, false)


func _on_repel_animation_animation_finished(anim_name: StringName) -> void:
	if anim_name == &"repel" and repelling:
		repel_animation.play(&"repel")
