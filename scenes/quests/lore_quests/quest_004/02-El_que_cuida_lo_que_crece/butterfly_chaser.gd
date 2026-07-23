# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D
## Mariposa ENEMIGA que vuela LENTO hacia el jugador y lo derrota al tocarlo.
## Vuela libre (ignora paredes y el vacío), así que persigue por toda la sala.
## No toca al jugador base: solo lee su posición y, al contacto, llama defeat().

## Velocidad de vuelo (px/s). Baja = el jugador puede correr más rápido.
@export var speed: float = 48.0
## Si está activo, al tocar al jugador lo derrota.
@export var defeat_on_touch: bool = true

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var touch_area: Area2D = $TouchArea


func _ready() -> void:
	if sprite.sprite_frames:
		sprite.play()
	touch_area.body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if player == null:
		return
	var to_player := player.global_position - global_position
	if to_player.length() > 2.0:
		global_position += to_player.normalized() * speed * delta
		sprite.flip_h = to_player.x < 0.0


func _on_body_entered(body: Node2D) -> void:
	if defeat_on_touch and body.is_in_group(&"player") and body.has_method("defeat"):
		body.defeat()
