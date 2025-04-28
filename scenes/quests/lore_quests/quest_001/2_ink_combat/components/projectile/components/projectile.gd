# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
## A RigidBody2D that can be thrown between enemies and player. It has a label too, and it can
## be used to fill barrels with the matching label.
class_name Projectile
extends RigidBody2D

const WALLS_HITBOX_LAYER: int = 5
const PLAYER_HITBOX_LAYER: int = 6
const ENEMY_HITBOX_LAYER: int = 7

## The projectile can fill barrels with the matching label.
@export var label: String = "???"

## Optional color. Use it together with the label to make a color-matching game.
@export var color: Color:
	set = _set_color

## Whether this projectile hits the player or the enemies.
@export var can_hit_enemy: bool = false:
	set = _set_can_hit_enemy

@export_group("Movement")

## The speed of the initial impulse and the bouncing impulse.
@export_range(10., 100., 5., "or_greater", "or_less", "suffix:m/s") var speed: float = 30.0

## The initial direction.
@export var direction: Vector2 = Vector2(0, -1):
	set = _set_direction

## The life span of the projectile.
@export_range(0., 10., 0.1, "or_greater", "suffix:s") var duration: float = 5.0

## If set, the projectile will constantly adjust itself to target this node. It will still start
## moving in the initial [member direction].
@export var node_to_follow: Node2D = null

@export_group("FXs")

## A small visual effect used when the projectile collides with things.
@export var small_fx_scene: PackedScene = preload(
	"res://scenes/quests/lore_quests/quest_001/2_ink_combat/components/splash/splash.tscn"
)

## A big visual effect used when the projectile explodes.
@export var big_fx_scene: PackedScene = preload(
	"res://scenes/quests/lore_quests/quest_001/2_ink_combat/components/big_splash/big_splash.tscn"
)

## If a projectile spawns in an elevated terrain, we turn off collisions with walls.
## We turn those collisions on again when the projectile has left the elevated terrain.
var elevated_terrain_layer: TileMapLayer

@onready var visible_things: Node2D = %VisibleThings
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var gpu_particles_2d: GPUParticles2D = %GPUParticles2D
@onready var duration_timer: Timer = %DurationTimer
@onready var hit_sound: AudioStreamPlayer2D = %HitSound


func _set_color(new_color: Color) -> void:
	color = new_color
	modulate = color if color else Color.WHITE


func _set_direction(new_direction: Vector2) -> void:
	if not new_direction.is_normalized():
		direction = new_direction.normalized()
	else:
		direction = new_direction


func _set_can_hit_enemy(new_can_hit_enemy: bool) -> void:
	can_hit_enemy = new_can_hit_enemy
	set_collision_mask_value(PLAYER_HITBOX_LAYER, not can_hit_enemy)
	set_collision_mask_value(ENEMY_HITBOX_LAYER, can_hit_enemy)
	animation_player.speed_scale = 2 if can_hit_enemy else 1
	gpu_particles_2d.amount_ratio = 1. if can_hit_enemy else .1


func _ready() -> void:
	_set_color(color)
	duration_timer.wait_time = duration
	duration_timer.start()
	var impulse: Vector2 = direction * speed
	apply_impulse(impulse)
	hit_sound.play()
	## TODO: find a better way to fetch all the tilemap layers that doesn't
	## involve going through ALL the nodes in the current scene.
	## Maybe groups?, it needs extra setup when creating the level, but may be
	## worth it.
	var tile_map_layers = get_tree().current_scene.find_children("", "TileMapLayer", true, false)
	for tile_map_layer: TileMapLayer in tile_map_layers:
		var tile_data = _get_tile_data(tile_map_layer, position)
		if tile_data and tile_data.get_custom_data("elevation") > 0:
			elevated_terrain_layer = tile_map_layer
			set_collision_mask_value(WALLS_HITBOX_LAYER, false)


func _process(_delta: float) -> void:
	visible_things.rotation = linear_velocity.angle()
	if node_to_follow:
		var direction_to_target: Vector2 = global_position.direction_to(
			node_to_follow.global_position
		)
		var force: Vector2 = direction_to_target * speed
		constant_force = force

	if elevated_terrain_layer:
		if (
			not _get_tile_data(elevated_terrain_layer, position)
			and not %DetectElevatedTerrain.overlaps_body(elevated_terrain_layer)
		):
			elevated_terrain_layer = null
			set_collision_mask_value(WALLS_HITBOX_LAYER, true)


func _get_tile_data(layer: TileMapLayer, local_projectile_position: Vector2 = position) -> TileData:
	var global_projectile_position = to_global(local_projectile_position)
	var local_map_position = layer.local_to_map(layer.to_local(global_position))
	var tile_data: TileData = layer.get_cell_tile_data(local_map_position)
	return tile_data


## Add a small effect scene to the current scene in the current position.
func add_small_fx() -> void:
	var small_fx: Node2D = small_fx_scene.instantiate()
	if color:
		small_fx.modulate = color
	get_tree().current_scene.add_child(small_fx)
	small_fx.global_position = global_position


func _on_body_entered(body: Node2D) -> void:
	if body.owner is FillingBarrel and not can_hit_enemy:
		return
	add_small_fx()
	duration_timer.start()
	if body.owner is FillingBarrel:
		var filling_barrel: FillingBarrel = body.owner as FillingBarrel
		if filling_barrel.label == label:
			filling_barrel.fill()
			queue_free()


func hit_by(attack: Node2D) -> void:
	var hit_speed := 100.0
	var hit_vector: Vector2 = attack.global_position.direction_to(global_position) * hit_speed
	can_hit_enemy = true
	hit_sound.play()
	linear_velocity = Vector2.ZERO
	apply_impulse(hit_vector)


func explode() -> void:
	var big_fx: Node2D = big_fx_scene.instantiate()
	if color:
		big_fx.modulate = color
	get_tree().current_scene.add_child(big_fx)
	big_fx.global_position = global_position
	queue_free()


func _on_duration_timer_timeout() -> void:
	explode()


## Remove the ball from the scene after the goal is reached.
## Wait a short random time and then explode.
func remove() -> void:
	await get_tree().create_timer(randf_range(0., 3.)).timeout
	explode()
