extends Node2D

const SPEED = 150
const DISTANCIA_PUERTA = 50.0

func _physics_process(_delta):
	var player = $Player
	var velocity = Vector2.ZERO
	
	# Verificar si está cerca de la puerta
	if player.position.distance_to($Puerta.position) < DISTANCIA_PUERTA:
		if Input.is_action_just_pressed("ui_accept"):
			get_tree().change_scene_to_file("res://scenes/quests/story_quests/the_last_cards/3.The_House_of_Words/scenes/Room1.tscn")
	
	if Input.is_action_pressed("ui_right"):
		velocity.x = SPEED
		$Player/AnimatedSprite2D.flip_h = false
		$Player/AnimatedSprite2D.play("walk")
	elif Input.is_action_pressed("ui_left"):
		velocity.x = -SPEED
		$Player/AnimatedSprite2D.flip_h = true
		$Player/AnimatedSprite2D.play("walk")
	elif Input.is_action_pressed("ui_up"):
		velocity.y = -SPEED
		$Player/AnimatedSprite2D.play("walk")
	elif Input.is_action_pressed("ui_down"):
		velocity.y = SPEED
		$Player/AnimatedSprite2D.play("walk")
	else:
		$Player/AnimatedSprite2D.play("idle")
	
	player.velocity = velocity
	player.move_and_slide()

func _on_puerta_body_entered(body):
	if body.name == "Player":
		get_tree().change_scene_to_file("res://scenes/Room1.tscn")
