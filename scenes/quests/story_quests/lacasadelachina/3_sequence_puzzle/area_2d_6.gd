extends Area2D

func _ready():
	$AnimationPlayer.play("seis")
	$AnimationPlayer.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(anim_name):
	$AnimationPlayer.play("seis")

func _on_body_entered(body):
	get_tree().reload_current_scene()
