extends CharacterBody2D

@export var movement_speed = 20.0
@export var hp = 10
@onready var player = get_tree().get_first_node_in_group("beeplayer")
@onready var sprite = $Sprite2D
@onready var flyTimer = get_node("%flyTimer")

func _physics_process(_delta):
	var direction = global_position.direction_to(player.global_position)
	velocity = direction*movement_speed
	move_and_slide()
	if direction.x > 0.1:
		sprite.flip_h = true
	elif direction.x < -0.1:
		sprite.flip_h = false
	if velocity != Vector2.ZERO:
		if flyTimer.is_stopped():
			if sprite.frame >= sprite.hframes - 1:
				sprite.frame = 0
			else:
				sprite.frame += 1
			flyTimer.start()
		

func _on_hurt_box_hurt(damage: Variant) -> void:
	hp -= damage
	if hp <= 0:
		queue_free()
