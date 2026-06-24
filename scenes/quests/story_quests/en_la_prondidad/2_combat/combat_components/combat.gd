extends Node2D

signal combate_ganado
signal combate_perdido

@export var enemigo: Node
@export var corazon: Node
@export var sprite_derrota: Sprite2D

@export var tiempo_cerrar_al_ganar: float = 2.0
@export var tiempo_reiniciar_al_perder: float = 2.0

var combate_terminado: bool = false

func _ready() -> void:
	if sprite_derrota != null:
		sprite_derrota.visible = false

	if enemigo != null:
		enemigo.jefe_muerto.connect(_on_jefe_muerto)

	if corazon != null:
		corazon.murio.connect(_on_corazon_murio)

func _on_jefe_muerto() -> void:
	if combate_terminado:
		return

	combate_terminado = true

	await get_tree().create_timer(tiempo_cerrar_al_ganar).timeout

	combate_ganado.emit()
	queue_free()

func _on_corazon_murio() -> void:
	if combate_terminado:
		return

	combate_terminado = true

	if sprite_derrota != null:
		sprite_derrota.visible = true

	await get_tree().create_timer(tiempo_reiniciar_al_perder).timeout

	combate_perdido.emit()
	queue_free()
