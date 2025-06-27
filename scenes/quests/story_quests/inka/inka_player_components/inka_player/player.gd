extends CharacterBody2D
class_name InkaPlayer  # antes: Player

@export var max_speed := 150
@export var attack_cooldown := 0.5

@onready var visuals: Node2D = $Visuals
@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D
@onready var collision_hit: CollisionShape2D = $Visuals/AnimatedSprite2D/Area2D/Collision_Hit
@onready var marker: Marker2D = $Marker2D
@export var max_health: int = 5

var current_health: int
var bala_path = preload("res://scenes/quests/story_quests/inka/inka_player_components/inka_player/bala.tscn")

var is_attacking: bool = false
var can_attack: bool = true
var pending_shot: bool = false  # <-- para saber si se va a disparar luego de la animación

func _ready() -> void:
	current_health = max_health
	animated_sprite_2d.play("Idle")
	animated_sprite_2d.connect("animation_finished", Callable(self, "_on_animation_finished"))
	collision_hit.disabled = true

func _physics_process(delta: float) -> void:
	handle_attack()
	if not is_attacking:
		handle_movement()
	handle_flip()

func handle_movement() -> void:
	var input_vector = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized()

	velocity = input_vector * max_speed
	move_and_slide()

	if input_vector.length() > 0:
		if animated_sprite_2d.animation != "Run":
			animated_sprite_2d.play("Run")
	else:
		if animated_sprite_2d.animation != "Idle":
			animated_sprite_2d.play("Idle")

func handle_flip() -> void:
	var input_x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	if input_x != 0:
		var facing_left = input_x < 0
		animated_sprite_2d.flip_h = facing_left

		var pos = collision_hit.position
		pos.x = abs(pos.x)
		if facing_left:
			pos.x *= -1
		collision_hit.position = pos

		var marker_pos = marker.position
		marker_pos.x = abs(marker_pos.x)
		if facing_left:
			marker_pos.x *= -1
		marker.position = marker_pos

func handle_attack() -> void:
	if Input.is_action_just_pressed("attack") and can_attack and not is_attacking:
		is_attacking = true
		can_attack = false
		animated_sprite_2d.play("Attack_Melee")
		collision_hit.disabled = false

	elif Input.is_action_just_pressed("shot") and not is_attacking:
		is_attacking = true
		pending_shot = true  # <-- se activa el disparo al finalizar animación
		animated_sprite_2d.play("Attack_Orbe")

func fire():
	var bala = bala_path.instantiate()
	bala.position = marker.global_position
	get_parent().add_child(bala)

func _on_animation_finished() -> void:
	match animated_sprite_2d.animation:
		"Attack_Melee":
			collision_hit.disabled = true
			start_attack_cooldown()
		"Attack_Orbe":
			if pending_shot:
				fire()
				pending_shot = false

	if animated_sprite_2d.animation.begins_with("Attack"):
		is_attacking = false
		animated_sprite_2d.play("Idle")

func start_attack_cooldown() -> void:
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func take_damage(amount: int) -> void:
	current_health -= amount
	print("¡Recibí daño! Vida restante: ", current_health)
	if current_health <= 0:
		die()

func die() -> void:
	print("¡Has muerto!")
	queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		body.queue_free()
