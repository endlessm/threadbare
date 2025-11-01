extends Area2D

var level = 1
var hp = 9999
var speed = 400.0
var damage = 10
var knockback_amount = 100
var paths = 1
var attack_size = 1.0
var attack_speed = 5.0

var target = Vector2.ZERO
var target_array = []

var angle = Vector2.ZERO
var reset_pos = Vector2.ZERO

var spr_bees_reg = preload("res://scenes/quests/story_quests/ne_expo/ne_expo_components/Attack Components/baby bee.png")
var spr_bees_attack = preload("res://scenes/quests/story_quests/ne_expo/ne_expo_components/Attack Components/angry baby bee.png")

@onready var player = get_tree().get_first_node_in_group("beeplayer")
@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D
@onready var attackTimer = get_node("%AttackTimer")
@onready var changeDirectionTimer = get_node("%ChangeDirection")
@onready var resetPosTimer = get_node("%ResetPosTimer")
@onready var sound_attack = $sound_attack

signal remove_from_array(object)

func _ready():
	update_bees()
	_on_reset_pos_timer_timeout()
	
func update_bees():
	level = player.attackbees_level
	match level:
		1:
			hp = 9999
			speed = 400.0
			damage = 10
			knockback_amount = 100
			paths = 3
			attack_size = 1.0
			attack_speed = 5.0
	scale = Vector2(.5,.5) * attack_size
	attackTimer.wait_time = attack_speed

func _physics_process(delta: float) -> void:
	if target_array.size() > 0:
		position += angle*speed*delta
	else:
		var player_angle = global_position.direction_to(reset_pos)
		var distance_dif = global_position - player.global_position
		var return_speed = 80
		if abs(distance_dif.y) > 200 or abs(distance_dif.x) > 200:
			return_speed = 150
		position += player_angle*return_speed*delta
		#rotation = global_position.direction_to(player.global_position).angle() + deg_to_rad(135)

func add_paths():
	sound_attack.play()
	emit_signal("remove_from_array", self)
	target_array.clear()
	var counter = 0
	while counter < paths:
		var new_path = player.get_random_target()
		target_array.append(new_path)
		counter += 1
	enable_attack(true)
	target = target_array[0]
	process_path()
	
func process_path():
	angle = global_position.direction_to(target)
	changeDirectionTimer.start()
	#var tween = create_tween()
	#var new_rotation_degrees = angle.angle() + deg_to_rad(135)
	#tween.tween_property(self,"rotation",new_rotation_degrees,0.25).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	#tween.play()
	
func enable_attack(atk = true):
	if atk:
		collision.call_deferred("set", "disabled", false)
		sprite.texture = spr_bees_attack
	else:
		collision.call_deferred("set", "disabled", true)
		sprite.texture = spr_bees_reg

func _on_attack_timer_timeout() -> void:
	add_paths()


func _on_change_direction_timeout() -> void:
	if target_array.size() > 0:
		target_array.remove_at(0)
		if target_array.size() > 0:
			target = target_array[0]
			process_path()
			sound_attack.play()
			emit_signal("remove_from_array", self)
		else:
			changeDirectionTimer.stop()
			attackTimer.start()
			enable_attack(false)
	else:
		changeDirectionTimer.stop()
		attackTimer.start()
		enable_attack(false)


func _on_reset_pos_timer_timeout() -> void:
		var choose_direction = randi() % 4
		reset_pos = player.global_position
		match choose_direction:
			0:
				reset_pos.x += 25
			1:
				reset_pos.x -= 25
			2:
				reset_pos.y += 25
			3:
				reset_pos.y -= 25
