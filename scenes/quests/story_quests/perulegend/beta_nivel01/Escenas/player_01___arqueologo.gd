extends CharacterBody2D

@export var move_speed:float
var is_facing_right = true
@onready var animated_sprite = $Sprite2D

func _physics_process(delta):
	move_x()
	move_y()
	flip_x()
	udate_animation()
	move_and_slide()
	
	
func udate_animation():
	if velocity.x:
		animated_sprite.play("runx")
	else:
		if velocity.y < 0:
			animated_sprite.play("runytop")
		else: 
			if velocity.y > 0:
				animated_sprite.play("runydown")
			else:
				if (velocity.x == 0) and (velocity.y == 0):
					animated_sprite.play("static")
			
	
	
func flip_x():
	#Girar si se esta mirando a la derecha y aprieto a la izquierda
	if (is_facing_right and velocity.x < 0) or (not is_facing_right and velocity.x > 0):
		scale.x *= -1
		is_facing_right = not is_facing_right
	#Girar si se esta mirando a la izqueirda y aprieto a la derecha
	
func move_x():
	var input_axis = Input.get_axis("move_left", "move_right")
	velocity.x = input_axis * move_speed
		
func move_y():
	var input_axis_Y = Input.get_axis("move_Up","move_down")
	velocity.y = input_axis_Y * move_speed
