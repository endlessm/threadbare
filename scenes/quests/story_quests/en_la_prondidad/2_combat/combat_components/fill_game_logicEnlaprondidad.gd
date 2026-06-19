class_name CustomStealthGameLogic
extends Node
signal goal_reached

@export var jefe: Node
@export var autostart: bool = false

var goal_already_reached: bool = false

func _ready() -> void:
	if jefe != null and jefe.has_signal("combate_completado"):
		jefe.combate_completado.connect(_on_jefe_derrotado)
	else:
		push_warning("El jefe no tiene la señal combate_completado o no fue asignado.")

	if autostart:
		start()


func start() -> void:
	get_tree().call_group("throwing_enemy", "start")


func _on_jefe_derrotado() -> void:
	if goal_already_reached:
		return

	goal_already_reached = true

	get_tree().call_group("throwing_enemy", "remove")
	get_tree().call_group("projectiles", "remove")

	goal_reached.emit()
