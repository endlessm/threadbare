extends Node2D

@onready var area_2d: Area2D = $Area2D

var consumed: bool = false


func _ready() -> void:
	area_2d.body_entered.connect(_on_area_body_entered)


func _on_area_body_entered(body: Node2D) -> void:
	if consumed:
		return

	if not body.is_in_group("player"):
		return

	consumed = true

	if body.has_method("activate_mushroom_vision"):
		body.activate_mushroom_vision()

	queue_free()
