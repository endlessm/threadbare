
extends CharacterBody2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@export var speed := 150.0

var player: Node2D
var chasing := true
var active := false

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	behavior_loop()

func _physics_process(delta: float) -> void:
	if player == null:
		return

	if active and chasing:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		animated_sprite.play("walk")
	else:
		velocity = Vector2.ZERO
		animated_sprite.play("idle")

	move_and_slide()

func behavior_loop() -> void:
	while true:
		chasing = true
		await get_tree().create_timer(5.0).timeout

		chasing = false
		await get_tree().create_timer(3.0).timeout


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		body.defeat()
