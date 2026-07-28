# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CharacterBody2D
## Roca EMPUJABLE estilo Sokoban: se mueve CUBO POR CUBO (una casilla por empujón)
## cuando el jugador la empuja con el cuerpo. Mientras se desliza "tiembla" (shader
## menhir_tremble) dando sensación de movimiento.
##
## Está en el grupo "pushable_box" para que la [PressurePlate] la detecte encima.
## No toca al jugador ni a ningún script base: solo lee la intención de movimiento
## (las teclas) y comprueba con [method PhysicsBody2D.test_move] si la casilla
## destino está libre.

## Tamaño de la casilla en px (cuánto avanza la roca por paso).
@export var cell_size: float = 64.0
## Duración del deslizamiento de un paso, en segundos.
@export var step_time: float = 0.12
## Cuánto tiembla mientras se mueve.
@export var tremble_amplitude: float = 1.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var push_sensor: Area2D = $PushSensor

var _moving: bool = false


func _ready() -> void:
	add_to_group(&"pushable_box")
	# Material propio (si no, varias rocas temblarían a la vez).
	if sprite.material:
		sprite.material = sprite.material.duplicate()
	_set_tremble(0.0)


func _physics_process(_delta: float) -> void:
	if _moving:
		return

	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if player == null or not push_sensor.overlaps_body(player):
		return

	# Intención de movimiento (las teclas), no la velocidad ya frenada por chocar.
	var input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if input.length() < 0.5:
		return

	var dir := _cardinal(input)
	# Solo empuja si el jugador está del lado opuesto (presiona HACIA la roca).
	if (global_position - player.global_position).dot(dir) <= 0.0:
		return

	var step := dir * cell_size
	# No avanzar si la casilla destino está bloqueada (muro / portón cerrado).
	if test_move(global_transform, step):
		return

	_step_to(global_position + step)


## Reduce el vector de entrada a una sola dirección cardinal (la dominante).
func _cardinal(v: Vector2) -> Vector2:
	if absf(v.x) >= absf(v.y):
		return Vector2(signf(v.x), 0.0)
	return Vector2(0.0, signf(v.y))


func _step_to(target: Vector2) -> void:
	_moving = true
	_set_tremble(tremble_amplitude)
	var tween := create_tween()
	tween.tween_property(self, "global_position", target, step_time)
	tween.tween_callback(_finish_step)


func _finish_step() -> void:
	_moving = false
	_set_tremble(0.0)


func _set_tremble(amount: float) -> void:
	if sprite.material is ShaderMaterial:
		(sprite.material as ShaderMaterial).set_shader_parameter(&"amplitude", amount)
