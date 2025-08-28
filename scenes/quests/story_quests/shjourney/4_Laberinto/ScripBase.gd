extends Node2D

var llaves: int = 0
@export var llaves_maximas: int = 3
@onready var puerta: StaticBody2D = $Puerta

func ActualizarLlaves():
	if llaves >= llaves_maximas:
		puerta.queue_free()


func _on_timer_puerta_timeout() -> void:
	$"CamaraPuerta".enabled = false
	$"Player/Camera2D".enabled = true
	$CamaraPuerta/InteractInput.visible = false  # Oculta cuando vuelve al jugador
