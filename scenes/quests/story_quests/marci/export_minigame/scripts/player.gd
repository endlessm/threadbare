extends CharacterBody2D

@export var speed := 200.0
@export var shoot_delay := 0.5
var shoot_timer := 0.0
var hp := 5

@onready var main = get_tree().get_first_node_in_group("main")

func _ready():
	add_to_group("player")

func _physics_process(delta):
	var dir = Vector2.ZERO
	if Input.is_action_pressed("ui_up"):
		dir.y -= 1
	if Input.is_action_pressed("ui_down"):
		dir.y += 1
	if Input.is_action_pressed("ui_left"):
		dir.x -= 1
	if Input.is_action_pressed("ui_right"):
		dir.x += 1

	velocity = dir.normalized() * speed if dir != Vector2.ZERO else Vector2.ZERO
	move_and_slide()

	shoot_timer -= delta
	if shoot_timer <= 0:
		shoot()
		shoot_timer = shoot_delay

func shoot():
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty(): 
		return

	var nearest = enemies[0]
	var min_dist = global_position.distance_to(nearest.global_position)
	for e in enemies:
		var d = global_position.distance_to(e.global_position)
		if d < min_dist:
			min_dist = d
			nearest = e

	var dir = (nearest.global_position - global_position).normalized()
	var b = preload("res://scenes/quests/story_quests/marci/export_minigame/scenes/bullet.tscn").instantiate()
	b.global_position = global_position
	b.direction = dir
	main.add_child(b)
	
	

func take_damage(amount):
	hp -= amount
	main.update_hud()
	if hp <= 0:
		queue_free()
		main.game_over()
