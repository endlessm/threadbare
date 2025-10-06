extends CharacterBody2D

var hp = 80
var last_movement = Vector2.UP

#Attacks
var iceSpear = preload("res://scenes/quests/story_quests/ne_expo/1_Bee Level/Bee Level Scenes/Attack/ice_spear.tscn")
var tornado = preload("res://scenes/quests/story_quests/ne_expo/1_Bee Level/Bee Level Scenes/Attack/tornado.tscn")
var attackbees = preload("res://scenes/quests/story_quests/ne_expo/1_Bee Level/Bee Level Scenes/Attack/attack_bees.tscn")

#AttackNodes
@onready var iceSpearTimer = get_node("%IceSpearTimer")
@onready var iceSpearAttackTimer = get_node("%IceSpearATtackTimer")
@onready var tornadoTimer = get_node("%TornadoTimer")
@onready var tornadoAttackTimer = get_node("%TornadoAttackTimer")
@onready var attackBeesBase = get_node("%AttackBeesBase")

#IceSpear
var icespear_ammo = 0
var icespear_baseammo = 1
var icespear_attackspeed = 1.5
var icespear_level = 1

#Tornado
var tornado_ammo = 0
var tornado_baseammo = 1
var tornado_attackspeed = 3
var tornado_level = 1

#AttackBees
var attackbees_ammo = 3
var attackbees_level = 1

#Enemy Related
var enemy_close = []


@export var movement_speed = 250.0
@onready var sprite = $"Bee (player)"
@onready var spriteShadow = $"Bee (player)/Shadow (player)"

func _ready():
	attack()
	
	
	
func _physics_process(delta: float) -> void:
	movement()
	
func movement():
	var mov := Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	if mov != Vector2.ZERO:
		last_movement = mov
	if mov.x > 0:
		sprite.flip_h = true
		spriteShadow.flip_h = true
	elif mov.x < 0:
		sprite.flip_h = false
		spriteShadow.flip_h = false
	velocity = mov.normalized()*movement_speed
	move_and_slide()
	
func attack():
	if icespear_level > 0:
		iceSpearTimer.wait_time = icespear_attackspeed
		if iceSpearTimer.is_stopped():
			iceSpearTimer.start()
	if tornado_level > 0:
		tornadoTimer.wait_time = tornado_attackspeed
		if tornadoTimer.is_stopped():
			tornadoTimer.start()
	if attackbees_level > 0:
		spawn_attackbees()
func _on_hurt_box_hurt(damage: Variant, _angle, _knockback) -> void:
	hp -= damage
	print(hp)


func _on_ice_spear_timer_timeout() -> void:
	icespear_ammo += icespear_baseammo
	iceSpearAttackTimer.start()


func _on_ice_spear_a_ttack_timer_timeout() -> void:
	if icespear_ammo > 0:
		var icespear_attack = iceSpear.instantiate()
		icespear_attack.position = position
		icespear_attack.target = get_random_target()
		icespear_attack.level = icespear_level
		add_child(icespear_attack)
		icespear_ammo -= 1
		if icespear_ammo > 0:
			iceSpearAttackTimer.start()
		else:
			iceSpearAttackTimer.stop()

func _on_tornado_timer_timeout() -> void:
	tornado_ammo += tornado_baseammo
	tornadoAttackTimer.start()

func _on_tornado_attack_timer_timeout() -> void:
	if tornado_ammo > 0:
		var tornado_attack = tornado.instantiate()
		tornado_attack.position = position
		tornado_attack.last_movement = last_movement
		tornado_attack.level = tornado_level
		add_child(tornado_attack)
		tornado_ammo -= 1
		if tornado_ammo > 0:
			tornadoAttackTimer.start()
		else:
			tornadoAttackTimer.stop()

func spawn_attackbees():
	var get_attackbees_total = attackBeesBase.get_child_count()
	var calc_spawns = attackbees_ammo - get_attackbees_total
	while calc_spawns > 0:
		var attackbees_spawn = attackbees.instantiate()
		attackbees_spawn.global_position = global_position
		attackBeesBase.add_child(attackbees_spawn)
		calc_spawns -= 1

func get_random_target():
	if enemy_close.size() > 0:
		return enemy_close.pick_random().global_position
	else:
		return Vector2.UP


func _on_enemy_detection_area_body_entered(body: Node2D) -> void:
	if not enemy_close.has(body):
		enemy_close.append(body)


func _on_enemy_detection_area_body_exited(body: Node2D) -> void:
	if enemy_close.has(body):
		enemy_close.erase(body)
