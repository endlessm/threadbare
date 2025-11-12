extends CharacterBody2D

@export var movement_speed = 20.0
@export var hp = 10
@export var knockback_recovery = 3.5
var knockback = Vector2.ZERO

@onready var player = get_tree().get_first_node_in_group("beeplayer")
@onready var sprite = $Sprite2D
@onready var flyTimer = get_node("%flyTimer")
@onready var snd_hit = $snd_hit

var death_anim = preload("res://scenes/quests/story_quests/ne_expo/1_Bee Level/Bee Level Scenes/Utility/explosion.tscn")
signal remove_from_array(object)


func _physics_process(_delta):
	knockback = knockback.move_toward(Vector2.ZERO, knockback_recovery)
	var direction = global_position.direction_to(player.global_position)
	velocity = direction*movement_speed
	velocity += knockback
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
		
func death():
	emit_signal("remove_from_array", self)
	var enemy_death = death_anim.instantiate()
	enemy_death.scale = sprite.scale
	enemy_death.global_position = global_position
	get_parent().call_deferred("add_child", enemy_death)
	queue_free()
	
func _on_hurt_box_hurt(damage: Variant, angle, knockback_amount) -> void:
	hp -= damage
	knockback = angle * knockback_amount
	if hp <= 0:
		death()
	else:
		snd_hit.play()
