extends "res://scenes/game_elements/characters/player/components/player_harm.gd"
var can_take_damage = true
signal  took_damage(cantidad:int)
func _on_hit_box_body_entered(body: Node2D) -> void:
	body = body as Projectile
	if not body:
		return
	if can_take_damage:
		can_take_damage=false	
		took_damage.emit(10)##10 de daño por cada disparo recibido
		body.add_small_fx()
		body.queue_free()
		got_hit_animation.play(&"got_hit")
		CameraShake.shake()
		##segundos de invulnerabilidad
		await get_tree().create_timer(0.5).timeout
		can_take_damage=true
