extends Area2D

@export var heal_amount: int = 20

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body is Player:
		body.heal(heal_amount)  # necesitarás crear el método heal() en Player
		queue_free()
