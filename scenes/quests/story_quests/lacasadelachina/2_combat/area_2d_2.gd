extends Area2D

func _ready():
	$AnimationPlayer.play("patrullar")
	$AnimationPlayer.get_animation("patrullar").loop_mode = Animation.LOOP_LINEAR
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Player":
		get_tree().reload_current_scene()
