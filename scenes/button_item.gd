extends Node2D
## A button that dissapears on contact with Player.

@onready var up_down_animation: AnimationPlayer = %UpDownAnimation


func _ready() -> void:
	# Delay the up and down animation according to the global position,
	# so multiple buttons in a row form a wave:
	up_down_animation.stop()
	var t: float = (sin(global_position.x) + 1) * 0.5 + (cos(global_position.y) + 1) * 0.5
	await get_tree().create_timer(t).timeout
	up_down_animation.play("up-down")


func _on_area_2d_area_entered(area: Area2D) -> void:
	# TODO: This is not added to an inventory or anything, is just cosmetic.
	if area.owner.is_in_group(&"player"):
		queue_free()
