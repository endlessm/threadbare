extends Area2D

func _ready():
	$AnimationPlayer.play("patrullar1")
	$AnimationPlayer.get_animation("patrullar1").loop_mode = Animation.LOOP_LINEAR
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Player":
		get_tree().reload_current_scene()
