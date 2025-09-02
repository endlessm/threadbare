extends CharacterBody2D

var hp = 80
@export var movement_speed = 250.0
@onready var sprite = $"Bee (player)"
@onready var spriteShadow = $"Bee (player)/Shadow (player)"


func _physics_process(delta: float) -> void:
	movement()
	
func movement():
	var x_mov = Input.get_action_strength("right") - Input.get_action_strength("left")
	var y_mov = Input.get_action_strength("down") - Input.get_action_strength("up")
	var mov = Vector2(x_mov, y_mov)
	if mov.x > 0:
		sprite.flip_h = true
		spriteShadow.flip_h = true
	elif mov.x < 0:
		sprite.flip_h = false
		spriteShadow.flip_h = false
	velocity = mov.normalized()*movement_speed
	move_and_slide()
	


func _on_hurt_box_hurt(damage: Variant) -> void:
	hp -= damage
	print(hp)
