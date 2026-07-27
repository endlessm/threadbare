# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends PathFollow2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var player = get_tree().get_first_node_in_group("player")

@export var base_speed: float = 0.050
@export var min_speed: float = 0.050
@export var max_speed: float = 0.07
@export var ideal_distance: float = 250.0
@export var too_close_distance: float = 200.0
@export var too_far_distance: float = 500.0
@export var defeat_distance: float = 550.0
@export var acceleration_factor: float = 0.03

var speed: float = base_speed
var moving: bool = false


func _ready() -> void:
	sprite.play("idle")


func _process(delta: float) -> void:
	if not moving:
		return

	if player:
		var distance = global_position.distance_to(player.global_position)

		# --- Ajuste de velocidad según distancia ---
		if distance > defeat_distance:
			print("🐑💨 La oveja escapó, el jugador pierde!")
			if player.has_method("defeat"):
				player.defeat()
			stop_moving()
			return

		elif distance < too_close_distance:
			# Jugador MUY cerca → oveja acelera (huye)
			speed = lerp(speed, max_speed, acceleration_factor)

		elif distance > too_far_distance:
			# Jugador muy lejos → oveja desacelera un poco
			speed = lerp(speed, min_speed, acceleration_factor)

		else:
			# Mantiene velocidad normal
			speed = lerp(speed, base_speed, acceleration_factor)

	progress_ratio += delta * speed

	# --- Animación ---
	if sprite.animation != "run":
		sprite.play("run")

	# --- Si llegó al final ---
	if progress_ratio >= 1.0:
		stop_moving()


func start_moving() -> void:
	if not moving:
		moving = true
		sprite.play("run")
		print("🐑 La oveja empezó a correr al detectar al jugador.")


func stop_moving() -> void:
	moving = false
	progress_ratio = clamp(progress_ratio, 0.0, 1.0)
	sprite.play("idle")
	print("🐑 La oveja llegó al final o se detuvo.")
