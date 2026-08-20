extends ThrowingEnemy
@export var reproduce_sonido:bool
@export var audio_disparo:AudioStreamPlayer

func _on_timeout() -> void:
	var player: Player = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		return
	_is_attacking = true
	animation_player.play(&"attack")
	timer.paused=true
	await get_tree().create_timer(0.7).timeout
	if reproduce_sonido:
		audio_disparo.play()
	timer.paused=false
	animation_player.queue(&"idle")
	
