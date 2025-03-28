class_name Splash
extends AnimatedSprite2D

@export_enum("Cyan", "Magenta", "Yellow", "Black") var ink_color_name: int = 0


func _ready() -> void:
	var color: Color = InkBlob.INK_COLORS[ink_color_name]
	modulate = color
	play(&"default")
	animation_looped.connect(_on_end)


func _on_end() -> void:
	queue_free()
