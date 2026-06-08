extends Node2D

const SPEED = 150

func _physics_process(delta):
	var player = $Player
	var velocity = Vector2.ZERO
	
	if Input.is_action_pressed("ui_right"):
		velocity.x = SPEED
		$Player/Sprite2D.flip_h = false
	elif Input.is_action_pressed("ui_left"):
		velocity.x = -SPEED
		$Player/Sprite2D.flip_h = true
	
	if Input.is_action_pressed("ui_up"):
		velocity.y = -SPEED
	elif Input.is_action_pressed("ui_down"):
		velocity.y = SPEED
	
	player.velocity = velocity
	player.move_and_slide()

func _on_puerta_body_entered(body):
	if body.name == "Player":
		get_tree().change_scene_to_file("res://scenes/Room1.tscn")
