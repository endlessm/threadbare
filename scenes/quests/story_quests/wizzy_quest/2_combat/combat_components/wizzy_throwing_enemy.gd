extends ThrowingEnemy
## Custom throwing enemy for Wizzy Quest
## Agrega comportamiento de temblor cuando se completa un barril

## SpriteFrames para cuando el proyectil está apagado
@export var projectile_disabled_sprite_frames: SpriteFrames


## Reproduce el efecto de temblor usando Tween (similar al Player)
func shake() -> void:
	var current_state := _get_state()
	# Solo tiembla si no está atacando o derrotado
	if current_state == State.ATTACKING or current_state == State.DEFEATED:
		return
	
	var original_pos := position
	var tween := create_tween()
	tween.tween_property(self, "position", original_pos + Vector2(5, 0), 0.05)
	tween.tween_property(self, "position", original_pos + Vector2(-5, 0), 0.05)
	tween.tween_property(self, "position", original_pos + Vector2(5, 0), 0.05)
	tween.tween_property(self, "position", original_pos + Vector2(-5, 0), 0.05)
	tween.tween_property(self, "position", original_pos, 0.05)
	await tween.finished


# Sobrescribir shoot_projectile para usar el proyectil personalizado
func shoot_projectile() -> void:
	var player: Player = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		return
	if not allowed_labels:
		_is_attacking = false
		return
	
	# Instanciar el proyectil
	var projectile: Projectile = projectile_scene.instantiate()
	projectile.direction = projectile_marker.global_position.direction_to(player.global_position)
	scale.x = 1 if projectile.direction.x < 0 else -1
	projectile.label = allowed_labels.pick_random()
	if projectile.label in color_per_label:
		projectile.color = color_per_label[projectile.label]
	projectile.global_position = projectile_marker.global_position + projectile.direction * distance
	if projectile_follows_player:
		projectile.node_to_follow = player
	projectile.sprite_frames = projectile_sprite_frames
	projectile.hit_sound_stream = projectile_hit_sound_stream
	projectile.small_fx_scene = projectile_small_fx_scene
	projectile.big_fx_scene = projectile_big_fx_scene
	projectile.trail_fx_scene = projectile_trail_fx_scene
	projectile.speed = projectile_speed
	projectile.duration = projectile_duration
	
	# Configurar el sprite apagado si el proyectil es de Wizzy
	if "disabled_sprite_frames" in projectile and projectile_disabled_sprite_frames:
		projectile.disabled_sprite_frames = projectile_disabled_sprite_frames
	
	get_tree().current_scene.add_child(projectile)
	_set_target_position()
	_is_attacking = false
