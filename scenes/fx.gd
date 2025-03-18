extends AnimatedSprite2D

const DEFAULT_FRAMES = preload("res://scenes/fx_frames_01.tres")

@export_enum("Cyan", "Magenta", "Yellow", "Black") var ink_color_name: int = 0
@export var frames: SpriteFrames

func _ready() -> void:
	var color: Color = Globals.INK_COLORS[ink_color_name]
	modulate = color
	if not frames:
		frames = DEFAULT_FRAMES
	sprite_frames = frames
	play(&"default")
	animation_looped.connect(_on_end)
	
func _on_end():
	queue_free()
