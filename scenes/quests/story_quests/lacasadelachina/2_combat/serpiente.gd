extends CharacterBody2D

@export var speed: float = 25.0
@export var player: CharacterBody2D


func _physics_process(_delta):
	# Si no hay jugador asignado, no hace nada
	if player == null:
		return

	# Calcula la dirección hacia el jugador constantemente
	var dir = (player.global_position - global_position).normalized()
	velocity = dir * speed

	move_and_slide()


func _on_hitbox_body_entered(body):
	if body.is_in_group("player") and body.has_method("defeat"):
		body.defeat()
