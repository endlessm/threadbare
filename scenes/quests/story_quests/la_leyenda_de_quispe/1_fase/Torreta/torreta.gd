extends Node2D

@export var bullet_scene: PackedScene
@export var fire_rate: float = 0.5
@export var follow_offset: Vector2 = Vector2(0, -20)
var can_shoot: bool = true
var player_in_range: bool = false
var player_ref: CharacterBody2D = null
var is_following: bool = false

func _ready() -> void:
	if $Timer:
		$Timer.wait_time = fire_rate
		$Timer.one_shot = true
		$Timer.timeout.connect(_on_timer_timeout)
	else:
		push_error("No se encontró Timer en la torreta")
	if $Area2D:
		$Area2D.body_entered.connect(_on_body_entered)
		$Area2D.body_exited.connect(_on_body_exited)
	else:
		push_error("No se encontró Area2D en la torreta")

func _process(_delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("interact") and can_shoot:
		shoot()
	if player_in_range and player_ref:
		is_following = Input.is_action_pressed("move_turret")
		if is_following:
			position = player_ref.global_position + follow_offset

func shoot() -> void:
	if bullet_scene == null:
		push_error("⚠️ bullet_scene no está asignado.")
		return
	if not $Marker2D:
		push_error("⚠️ Falta Marker2D en la torreta.")
		return
	can_shoot = false
	var bullet: Node2D = bullet_scene.instantiate()
	bullet.global_position = $Marker2D.global_position
	var shoot_dir: Vector2 = Vector2.UP
	bullet.direction = shoot_dir.normalized()
	get_tree().current_scene.add_child(bullet)
	$Timer.start()

func _on_timer_timeout() -> void:
	can_shoot = true

func _on_body_entered(body: Node) -> void:
	print("Entró:", body.name)
	if body is CharacterBody2D and body.name == "Jugador":
		player_in_range = true
		player_ref = body

func _on_body_exited(body: Node) -> void:
	if body is CharacterBody2D and body == player_ref:
		player_in_range = false
		player_ref = null
		is_following = false
