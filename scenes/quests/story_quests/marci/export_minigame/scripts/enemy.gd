extends CharacterBody2D

@export var speed := 80.0
@export var hp := 2
@onready var player = get_tree().get_first_node_in_group("player")

func _ready():
	add_to_group("enemies")
	$DamageArea.connect("body_entered", Callable(self, "_on_body_entered"))

func _physics_process(delta):
	if not player:
		return
	var dir = (player.position - position).normalized()
	velocity = dir * speed
	move_and_slide()

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage(1)
		queue_free()

func take_damage(amount):
	hp -= amount
	if hp <= 0:
		die()

func die():
	get_tree().get_first_node_in_group("main").enemy_killed()
	queue_free()
