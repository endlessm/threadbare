class_name InteractArea
extends Area2D

signal interaction_started
signal interaction_ended

@export var action: String = "Talk"


func start_interaction() -> void:
	interaction_started.emit()


func end_interaction() -> void:
	interaction_ended.emit()
