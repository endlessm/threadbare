@tool
class_name Platform
extends Node2D

const DEFAULT_TILE_SET = preload("res://spaces/tileset-threadbare.tres")

## Which tileset should be used to draw the platform?
@export var tile_set: TileSet = DEFAULT_TILE_SET:
	set = _set_tile_set

## How many tiles wide is the platform?
@export_range(1, 20, 1, "suffix:tiles") var width: int = 3:
	set = _set_width

## Can you jump through the bottom of the platform?
@export var one_way: bool = false:
	set = _set_one_way

@export_group("Falling Platform")

## Whether the platform should fall after the player-character touches it.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var fall: bool = false

## Number of seconds after touching the platform for it to fall.
## If set to [code]0[/code], the platform falls as soon as the player-character touches it.
## [br][br]
## Has no effect if [member fall] is disabled.
@export_range(0, 5, 0.1, "suffix:s", "or_greater") var fall_time: float = 2.0

var fall_timer: Timer

@onready var _rigid_body := %RigidBody2D
@onready var _sprites := %Sprites
@onready var _collision_shape := %CollisionShape2D
@onready var _area_collision_shape := %AreaCollisionShape2D
@onready var _animation_player := %AnimationPlayer


func _set_tile_set(new_tile_set):
	if new_tile_set:
		tile_set = new_tile_set
	else:
		tile_set = DEFAULT_TILE_SET

	if is_node_ready():
		_recreate_sprites()


func _set_width(new_width):
	width = new_width

	if is_node_ready():
		_recreate_sprites()


func _set_one_way(new_one_way):
	one_way = new_one_way

	if is_node_ready():
		_recreate_sprites()


func _recreate_sprites():
	for c in _sprites.get_children():
		c.queue_free()

	var tile_width := tile_set.tile_size.x
	var sprite: Texture2D = tile_set.get_source(tile_set.get_source_id(0)).texture

	_collision_shape.one_way_collision = one_way
	_collision_shape.shape.set_size(Vector2(width * tile_width, tile_width))
	_area_collision_shape.shape.set_size(
		Vector2(width * tile_width, _area_collision_shape.shape.size[1])
	)

	var center: float = (width - 1) * tile_width / 2.0

	for i in range(0, width):
		var new_sprite := Sprite2D.new()
		new_sprite.texture = sprite
		new_sprite.hframes = 12
		new_sprite.vframes = 3
		if one_way:
			if i == 0:
				if width == 1:
					new_sprite.frame_coords = Vector2i(8, 0)
				else:
					new_sprite.frame_coords = Vector2i(5, 0)
			elif i == width - 1:
				new_sprite.frame_coords = Vector2i(7, 0)
			else:
				new_sprite.frame_coords = Vector2i(6, 0)
		else:
			new_sprite.frame_coords = Vector2i(10, 1)
		new_sprite.position = Vector2(i * tile_width - center, 0)
		_sprites.add_child(new_sprite)


func _ready():
	_recreate_sprites()

	fall_timer = Timer.new()
	fall_timer.one_shot = true
	fall_timer.timeout.connect(_fall)
	add_child(fall_timer)


func _on_area_2d_body_entered(body):
	if not body.is_in_group("players"):
		return

	if not fall:
		return

	if fall_time > 0:
		fall_timer.start(fall_time)
		_animation_player.play("shake")
	else:
		_rigid_body.call_deferred("set_freeze_enabled", false)


func _fall():
	_rigid_body.freeze = false
	_animation_player.stop()
