# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D
## Flor "Stellaria" que FLORECE (se abre) como clímax del telar.
##
## Empieza como un capullo cerrado (pétalos encogidos e invisibles) y al
## acercarse el jugador despliega sus pétalos en estrella. Es procedural
## (Polygon2D), así que funciona sin ningún sprite: cuando tengas el arte de la
## flor puedes sustituir los Polygon2D por tus texturas y conservar el script.
## [br][br]
## Trigger por defecto: el área [code]BloomTrigger[/code] detecta al jugador.
## También puedes llamar [method bloom] desde un diálogo o el telar.

## Si está activo, florece cuando el jugador entra en el área de la flor.
@export var auto_bloom_on_touch: bool = true
## Duración de la apertura de cada pétalo (segundos).
@export var bloom_time: float = 1.2
## Marca para dejarla ya abierta en el editor (previsualización / estado inicial).
@export var start_bloomed: bool = false

@onready var petals: Node2D = $Petals
@onready var trigger: Area2D = $BloomTrigger

var _bloomed: bool = false


func _ready() -> void:
	# Estado cerrado: pétalos encogidos e invisibles.
	for petal: Node in petals.get_children():
		(petal as Node2D).scale = Vector2(0.06, 0.06)
	petals.modulate.a = 0.0

	if auto_bloom_on_touch and trigger:
		trigger.body_entered.connect(_on_body_entered)

	if start_bloomed:
		_snap_open()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		bloom()


## Abre la flor con una animación de pétalos escalonada. Idempotente.
func bloom() -> void:
	if _bloomed:
		return
	_bloomed = true

	var children := petals.get_children()
	for i: int in children.size():
		var petal := children[i] as Node2D
		var t := create_tween()
		t.tween_interval(i * (bloom_time * 0.12))
		(
			t
			. tween_property(petal, "scale", Vector2.ONE, bloom_time)
			. set_trans(Tween.TRANS_ELASTIC)
			. set_ease(Tween.EASE_OUT)
		)

	create_tween().tween_property(petals, "modulate:a", 1.0, bloom_time * 0.5)


func _snap_open() -> void:
	_bloomed = true
	for petal: Node in petals.get_children():
		(petal as Node2D).scale = Vector2.ONE
	petals.modulate.a = 1.0
