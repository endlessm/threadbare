# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends ThrowingEnemy

signal Defeated

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
	if projectile.label in color_per_label:
		projectile.color = color_per_label[projectile.label]
	projectile.global_position = (projectile_marker.global_position + (projectile.direction * 75.))
	if projectile_follows_player:
		projectile.node_to_follow = player
	projectile.sprite_frames = projectile_sprite_frames
	projectile.hit_sound_stream = projectile_hit_sound_stream
	projectile.small_fx_scene = projectile_small_fx_scene
	projectile.big_fx_scene = projectile_big_fx_scene
	projectile.trail_fx_scene = projectile_trail_fx_scene
	projectile.speed = projectile_speed
	projectile.duration = projectile_duration
	projectile.can_hit_enemy = true
	get_tree().current_scene.add_child(projectile)
	_set_target_position()
	_is_attacking = false
	
func _on_got_hit(body: Node2D) -> void:
	super(body)
	Defeated.emit()
	remove()
