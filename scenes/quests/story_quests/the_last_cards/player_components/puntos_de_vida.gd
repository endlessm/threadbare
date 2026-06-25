extends Area2D

@export var heal_amount: int = 5

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.heal(heal_amount)  # necesitarás crear el método heal() en Player
		queue_free()
