extends Area2D

@onready var grazingParticles = %grazeParticles

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		var enemy: JASBHenemy = get_tree().get_first_node_in_group("JASBHenemy")
		if enemy && enemy.rank > 0:
			enemy.rank = enemy.rank - 1
			if enemy.rank < enemy.rank_level_up && enemy.rank_level_up > 10:
				enemy.bullet_count = enemy.bullet_count - 2
				enemy.projectile_speed = enemy.projectile_speed - 5
				enemy.throwing_period = enemy.throwing_period + 0.25
				enemy.rank_level_up = enemy.rank_level_up - 10
		grazingParticles.set_emitting(true)

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		grazingParticles.set_emitting(false)
