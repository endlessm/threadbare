@tool
class_name Flag
extends Area2D

enum FlagPosition {
	DOWN,
	UP,
}

## Use this to change the sprite frames of the flag.
@export var sprite_frames: SpriteFrames = _initial_sprite_frames:
	set = _set_sprite_frames

@export var flag_position: FlagPosition = FlagPosition.DOWN:
	set = _set_flag_position

@onready var _sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var _initial_sprite_frames: SpriteFrames = %AnimatedSprite2D.sprite_frames


func _set_sprite_frames(new_sprite_frames):
	sprite_frames = new_sprite_frames
	if sprite_frames and is_node_ready():
		_sprite.sprite_frames = sprite_frames


func _set_flag_position(new_flag_position):
	flag_position = new_flag_position
	if not is_node_ready():
		pass
	elif flag_position == FlagPosition.DOWN:
		_sprite.play("down")
	else:
		_sprite.play("up")


# Called when the node enters the scene tree for the first time.
func _ready():
	_set_sprite_frames(sprite_frames)
	_set_flag_position(flag_position)


func _on_body_entered(_body):
	if flag_position == FlagPosition.DOWN:
		flag_position = FlagPosition.UP
		Global.raise_flag(self)
