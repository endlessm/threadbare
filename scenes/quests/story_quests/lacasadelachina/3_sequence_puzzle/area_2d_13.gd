extends Area2D

func _ready():
	$AnimationPlayer.play("diez")
	$AnimationPlayer.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(anim_name):
	$AnimationPlayer.play("diez")

func _on_body_entered(body):
	get_tree().reload_current_scene()
