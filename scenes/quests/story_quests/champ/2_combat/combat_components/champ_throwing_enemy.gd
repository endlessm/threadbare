@tool 
class_name ChampThrowingEnemy
extends ThrowingEnemy

## Key value pairs of labels and the corresponding Sprite Frames for projectiles
@export var project_sprite_frames: Dictionary[String, SpriteFrames] = {"label_name":preload("uid://b00dcfe4dtvkh")} 

## Overridden function to apply sprite frames dependent on projectile label
func shoot_projectile() -> void:
	var player: Player = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		return
	if not allowed_labels:
		_is_attacking = false
		return
	var projectile: Projectile = projectile_scene.instantiate()
	projectile.direction = projectile_marker.global_position.direction_to(player.global_position)
	scale.x = 1 if projectile.direction.x < 0 else -1
	projectile.label = allowed_labels.pick_random()
	if projectile.label in project_sprite_frames:
		projectile.sprite_frames = project_sprite_frames[projectile.label]
	else:
		# Default to original projectile sprite frames
		projectile.sprite_frames = preload("uid://b00dcfe4dtvkh")
	if projectile.label in color_per_label:
		projectile.color = color_per_label[projectile.label]
	projectile.global_position = projectile_marker.global_position + projectile.direction * distance
	if projectile_follows_player:
		projectile.node_to_follow = player
	projectile.hit_sound_stream = projectile_hit_sound_stream
	projectile.small_fx_scene = projectile_small_fx_scene
	projectile.big_fx_scene = projectile_big_fx_scene
	projectile.trail_fx_scene = projectile_trail_fx_scene
	projectile.speed = projectile_speed
	projectile.duration = projectile_duration
	get_tree().current_scene.add_child(projectile)
	_set_target_position()
	_is_attacking = false
