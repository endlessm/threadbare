# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0

extends Camera2D

@export var target_path: NodePath = NodePath("")
@export var follow_speed: float = 5.0
@export var random_strength: float = 60.0
@export var shake_fade: float = 3.0
@export var shake_interval: float = 2.0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var shake_strength: float = 0.0
var target: Node2D = null
var timer: float = 0.0

func _ready() -> void:
	# Buscar el Player
	if target_path != NodePath(""):
		target = get_node_or_null(target_path) as Node2D
	else:
		target = get_tree().get_first_node_in_group("player") as Node2D
		if target == null:
			target = get_parent().get_node_or_null("Player")

	# Activar esta cámara
	make_current()
	print("📷 Cámara activada, seguimiento y vibración automática cada %.1f s" % shake_interval)

func apply_shake() -> void:
	shake_strength = random_strength

func _process(delta: float) -> void:
	# Seguimiento del jugador
	if target != null:
		global_position = global_position.lerp(target.global_position, follow_speed * delta)

	# Temporizador para activar vibraciones periódicas
	timer += delta
	if timer >= shake_interval:
		apply_shake()
		timer = 0.0  # reiniciar el contador

	# Efecto de vibración
	if shake_strength > 0.0:
		shake_strength = lerpf(shake_strength, 0.0, shake_fade * delta)
		offset = random_offset()
	else:
		offset = Vector2.ZERO

func random_offset() -> Vector2:
	return Vector2(
		rng.randf_range(-shake_strength, shake_strength),
		rng.randf_range(-shake_strength, shake_strength)
	)
