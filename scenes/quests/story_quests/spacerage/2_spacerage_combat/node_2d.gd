extends Node2D
var vida_max=20
var vida = 20
@export var speed = 400

func _on_got_hit_animation_animation_changed(old_name: StringName, new_name: StringName) -> void:
	pass 
func _on_got_hit_animation_animation_started(animation_name: String) -> void:
	if animation_name == "got_hit":
		print("me golpearon")

func _on_hit_box_body_entered(body: Node2D) -> void:
		vida -= 2
		vida = clamp(vida, 0, vida_max)
		$"../vida".value = vida 
		$"../vida".max_value= vida_max 
