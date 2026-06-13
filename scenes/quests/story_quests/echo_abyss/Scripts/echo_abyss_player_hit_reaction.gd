extends "res://scenes/game_elements/characters/player/components/player_harm.gd"

func _on_hit_box_body_entered(body: Node2D) -> void:
	body = body as Projectile
	if not body:
		return

	body.add_small_fx()
	body.queue_free()
	CameraShake.shake()
	got_hit_animation.play(&"got_hit")
	
	var player := owner as EchoAbyssPlayer
	if player:
		player.take_damage(1)
	
