extends Area2D

@onready var grazingParticles = %grazeParticles

func _on_body_entered(body: Node2D) -> void:
	if body is Projectile:
		grazingParticles.set_emitting(true)


func _on_body_exited(body: Node2D) -> void:
	if body is Projectile:
		grazingParticles.set_emitting(false)
