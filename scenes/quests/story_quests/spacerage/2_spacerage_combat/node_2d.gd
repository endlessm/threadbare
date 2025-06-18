extends Node2D
var vida_max=20
var vida = 20

func _on_got_hit_animation_animation_changed(old_name: StringName, new_name: StringName) -> void:
	pass # Replace with function body.
	


func _on_got_hit_animation_animation_started(animation_name: String) -> void:
	if animation_name == "got_hit":
		print("me golpearon")
		vida -= 10
		vida = clamp(vida, 0, vida_max)
