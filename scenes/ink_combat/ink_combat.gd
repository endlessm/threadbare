extends Node2D

signal finished

@export var inkwells_to_win: int = 1

var inkwells_completed = 0

@onready var on_the_ground: Node2D = %OnTheGround


func _ready() -> void:
	for node: Node in on_the_ground.get_children():
		if node is not Inkwell:
			continue
		node = node as Inkwell
		node.completed.connect(_on_inkwell_completed)


func _on_inkwell_completed():
	inkwells_completed += 1
	if inkwells_completed >= inkwells_to_win:
		finished.emit()
