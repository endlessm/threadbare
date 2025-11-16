extends ThrowingEnemy
## Wizzy Quest throwing enemy with visual feedback
##
## Extends base ThrowingEnemy with:
## - Shake animation when player completes a barrel (visual feedback)
## - Support for disabled projectile sprites (two-state projectile system)
## - Faster throwing rate and projectile speed for combat puzzle difficulty

## Visual appearance for disabled projectiles
@export var projectile_disabled_sprite_frames: SpriteFrames

# Shake animation constants
const SHAKE_OFFSET := 5.0
const SHAKE_DURATION := 0.05

# Combat difficulty tuning
const CUSTOM_PROJECTILE_SPEED := 50.0  # m/s (default: 30.0)
const CUSTOM_THROWING_PERIOD := 3.0    # seconds (default: 5.0)

# Custom sprite frames
const WIZZY_SPRITE_FRAMES: SpriteFrames = preload("uid://bdop8df62qlht")


func _ready() -> void:
	super._ready()
	sprite_frames = WIZZY_SPRITE_FRAMES
	projectile_speed = CUSTOM_PROJECTILE_SPEED
	throwing_period = CUSTOM_THROWING_PERIOD


## Plays horizontal shake animation as feedback when barrel is completed
func shake() -> void:
	if not _can_shake():
		return
	
	var original_pos := position
	var tween := create_tween()
	
	# Shake pattern: right, left, right, left, center
	tween.tween_property(self, "position", original_pos + Vector2(SHAKE_OFFSET, 0), SHAKE_DURATION)
	tween.tween_property(self, "position", original_pos + Vector2(-SHAKE_OFFSET, 0), SHAKE_DURATION)
	tween.tween_property(self, "position", original_pos + Vector2(SHAKE_OFFSET, 0), SHAKE_DURATION)
	tween.tween_property(self, "position", original_pos + Vector2(-SHAKE_OFFSET, 0), SHAKE_DURATION)
	tween.tween_property(self, "position", original_pos, SHAKE_DURATION)
	
	await tween.finished


## Returns true if enemy can shake (not attacking or defeated)
func _can_shake() -> bool:
	var current_state := _get_state()
	return current_state != State.ATTACKING and current_state != State.DEFEATED


## Shoots projectile with support for disabled sprite configuration
func shoot_projectile() -> void:
	var player: Player = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player) or not allowed_labels:
		_is_attacking = false
		return
	
	var projectile := _create_configured_projectile(player)
	get_tree().current_scene.add_child(projectile)
	
	_set_target_position()
	_is_attacking = false


## Creates and configures projectile instance with all properties
func _create_configured_projectile(player: Player) -> Projectile:
	var projectile: Projectile = projectile_scene.instantiate()
	
	# Direction and position
	projectile.direction = projectile_marker.global_position.direction_to(player.global_position)
	projectile.global_position = projectile_marker.global_position + projectile.direction * distance
	scale.x = 1 if projectile.direction.x < 0 else -1
	
	# Label and color
	projectile.label = allowed_labels.pick_random()
	if projectile.label in color_per_label:
		projectile.color = color_per_label[projectile.label]
	
	# Tracking
	if projectile_follows_player:
		projectile.node_to_follow = player
	
	# Visual and audio
	projectile.sprite_frames = projectile_sprite_frames
	projectile.hit_sound_stream = projectile_hit_sound_stream
	projectile.small_fx_scene = projectile_small_fx_scene
	projectile.big_fx_scene = projectile_big_fx_scene
	projectile.trail_fx_scene = projectile_trail_fx_scene
	
	# Physics
	projectile.speed = projectile_speed
	projectile.duration = projectile_duration
	
	# Wizzy-specific: disabled sprite configuration
	if "disabled_sprite_frames" in projectile and projectile_disabled_sprite_frames:
		projectile.disabled_sprite_frames = projectile_disabled_sprite_frames
	
	return projectile
