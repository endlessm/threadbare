
class_name CustomStealthGameLogic
extends Node

signal goal_reached

@export var jefe: Node
@export var autostart: bool = false

var goal_already_reached: bool = false

func _ready() -> void:
	if jefe != null and jefe.has_signal("jefe_muerto"):
		jefe.connect("jefe_muerto", Callable(self, "_on_jefe_muerto"))

	if autostart:
		start()


func start() -> void:
	get_tree().call_group("throwing_enemy", "start")


func _on_jefe_muerto() -> void:
	if goal_already_reached:
		return

	goal_already_reached = true
	goal_reached.emit()
