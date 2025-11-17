extends Projectile
## Two-state sliding projectile for Wizzy Quest combat puzzle
##
## Two-state projectile system:
## - ACTIVE: Bounces and damages player when hit
## - DISABLED: Can be pushed by player to hit barrels and decrease their count
##
## Push mechanics:
## - Walk into projectile: Slow push (100 speed)
## - Attack near projectile: Fast push (300 speed)

## Visual appearance when projectile is disabled
@export var disabled_sprite_frames: SpriteFrames

## Speed when player walks into disabled projectile
@export var walk_push_speed: float = 100.0

## Speed when player attacks near disabled projectile  
@export var attack_push_speed: float = 300.0

# Physics constants for smooth sliding mechanics
const PROJECTILE_MASS := 3.0
const DISABLED_TINT := Color(0.5, 0.5, 0.5, 1.0)
const SLIDE_STOP_THRESHOLD := 10.0
const WALK_PUSH_DISTANCE := 50.0
const ATTACK_PUSH_DISTANCE := 100.0
const MOVEMENT_ALIGNMENT_THRESHOLD := 0.5

# State tracking
var _is_disabled: bool = false
var _is_sliding: bool = false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	super._ready()
	add_to_group("pushable_projectiles")


func _process(_delta: float) -> void:
	if not _is_disabled:
		return
	
	var player := _get_fighting_player()
	if not player:
		return
	
	var distance := global_position.distance_to(player.global_position)
	var push_direction := (global_position - player.global_position).normalized()
	
	# Attack push: High speed, longer range
	if Input.is_action_just_pressed(&"repel") and distance < ATTACK_PUSH_DISTANCE:
		push(push_direction, attack_push_speed)
	
	# Walk push: Low speed, close range, requires movement toward projectile
	elif _can_walk_push(player, distance):
		push(push_direction, walk_push_speed)


## Returns the player if they're in fighting mode, null otherwise
func _get_fighting_player() -> Player:
	var player: Player = get_tree().get_first_node_in_group("player")
	if player and player.mode == Player.Mode.FIGHTING:
		return player
	return null


## Checks if walk push conditions are met
func _can_walk_push(player: Player, distance: float) -> bool:
	if _is_sliding or distance >= WALK_PUSH_DISTANCE:
		return false
	
	if player.velocity.length() <= SLIDE_STOP_THRESHOLD:
		return false
	
	# Check if player is moving toward projectile
	var direction_to_projectile := (global_position - player.global_position).normalized()
	var movement_alignment := player.velocity.normalized().dot(direction_to_projectile)
	
	return movement_alignment > MOVEMENT_ALIGNMENT_THRESHOLD


func _physics_process(_delta: float) -> void:
	# Auto-reset sliding state when projectile stops
	if _is_sliding and linear_velocity.length() < SLIDE_STOP_THRESHOLD:
		_is_sliding = false


func got_hit(player: Player) -> void:
	if _is_disabled:
		return
	
	_is_disabled = true
	_stop_projectile_motion()
	_apply_disabled_visual()
	_configure_disabled_collision_layers()
	_configure_sliding_physics()
	
	duration_timer.stop()
	add_small_fx()
	hit_sound.play()


## Stops all projectile motion and tracking
func _stop_projectile_motion() -> void:
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	constant_force = Vector2.ZERO
	gravity_scale = 0.0
	node_to_follow = null


## Changes sprite to disabled appearance
func _apply_disabled_visual() -> void:
	if disabled_sprite_frames:
		animated_sprite_2d.sprite_frames = disabled_sprite_frames
		animated_sprite_2d.play(&"disabled")
	else:
		modulate = DISABLED_TINT


## Configures collision layers for disabled state
func _configure_disabled_collision_layers() -> void:
	# Disable player damage
	can_hit_player = false
	set_collision_mask_value(Enums.CollisionLayers.PLAYERS_HITBOX, false)
	
	# Change from PROJECTILES to NON_WALKABLE_FLOOR layer
	set_collision_layer_value(Enums.CollisionLayers.PROJECTILES, false)
	set_collision_layer_value(Enums.CollisionLayers.NON_WALKABLE_FLOOR, true)
	
	# Enable collisions with environment and entities
	set_collision_mask_value(Enums.CollisionLayers.WALLS, true)
	set_collision_mask_value(Enums.CollisionLayers.PLAYERS, true)
	set_collision_mask_value(Enums.CollisionLayers.PROJECTILES, true)
	set_collision_mask_value(Enums.CollisionLayers.NON_WALKABLE_FLOOR, true)
	set_collision_mask_value(Enums.CollisionLayers.ENEMIES_HITBOX, false)


## Configures physics for smooth frictionless sliding
func _configure_sliding_physics() -> void:
	mass = PROJECTILE_MASS
	lock_rotation = true
	gravity_scale = 0.0
	
	# Zero friction and bounce for smooth sliding
	var material := PhysicsMaterial.new()
	material.friction = 0.0
	material.bounce = 0.0
	physics_material_override = material
	
	# Continuous collision detection to prevent corner sticking
	contact_monitor = true
	max_contacts_reported = 4
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE


## Pushes disabled projectile in cardinal direction at specified speed
func push(direction: Vector2, speed: float = 0.0) -> void:
	if not _is_disabled or _is_sliding:
		return
	
	var push_speed := speed if speed > 0.0 else attack_push_speed
	var cardinal_direction := _to_cardinal_direction(direction)
	
	_is_sliding = true
	linear_velocity = cardinal_direction * push_speed


## Converts any direction to nearest cardinal direction (up/down/left/right)
func _to_cardinal_direction(direction: Vector2) -> Vector2:
	if abs(direction.x) > abs(direction.y):
		return Vector2(sign(direction.x), 0.0)
	else:
		return Vector2(0.0, sign(direction.y))


## Handles collision logic for both disabled and active states
func _on_body_entered(body: Node2D) -> void:
	if _is_disabled:
		_handle_disabled_collision(body)
	else:
		_handle_active_collision(body)


## Collision logic when projectile is disabled
func _handle_disabled_collision(body: Node2D) -> void:
	# Stop sliding on any collision
	if _is_sliding:
		linear_velocity = Vector2.ZERO
		_is_sliding = false
		add_small_fx()
	
	# Disabled projectile destroys active projectile
	if body is Projectile and not body.get("_is_disabled"):
		body.explode()
		explode()
		return
	
	# Disabled projectile decrements barrel (inverted mechanic)
	if body.owner is FillingBarrel:
		var barrel := body.owner as FillingBarrel
		if barrel.label == label and barrel.has_method("decrement"):
			barrel.decrement()
			explode()


## Collision logic when projectile is active
func _handle_active_collision(body: Node2D) -> void:
	# Active projectile destroys disabled projectile
	if body is Projectile and body.get("_is_disabled"):
		body.explode()
		explode()
		return
	
	# Active projectile increments barrel
	add_small_fx()
	duration_timer.start()
	if body.owner is FillingBarrel:
		var barrel := body.owner as FillingBarrel
		if barrel.label == label:
			barrel.increment()
			queue_free()


## Disabled projectiles don't explode on timeout
func _on_duration_timer_timeout() -> void:
	if _is_disabled:
		return
	super._on_duration_timer_timeout()
