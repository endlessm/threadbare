extends AnimatedSprite2D

const DEFAULT_FRAMES = preload("res://scenes/fx_frames_01.tres")

@export var frames: SpriteFrames

func _ready() -> void:
	if not frames:
		frames = DEFAULT_FRAMES
	sprite_frames = frames
	play(&"default")
	animation_looped.connect(_on_end)
	
func _on_end():
	queue_free()
