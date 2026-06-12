extends "res://scenes/game_elements/characters/player/components/player.gd"

class_name ElAbandonadoPlayer2

signal health_changed(current_health: int, max_health: int)

@export_group("Sword Attack")
@export var sword_damage: int = 25
@export var sword_active_frame_start: int = 1
@export var sword_active_frame_end: int = 2
@export var sword_attack_duration: float = 0.45

@export_group("Health")
@export var max_health: int = 100

var current_health: int
var is_attacking: bool = false
var sword_can_damage: bool = true
var last_attack_direction: Vector2 = Vector2.RIGHT

@onready var sword_hitbox: Area2D = get_node_or_null("SwordHitbox")
@onready var sword_collision: CollisionShape2D = get_node_or_null("SwordHitbox/CollisionShape2D")


func _ready() -> void:
	super._ready()

	current_health = max_health
	health_changed.emit(current_health, max_health)

	if sword_hitbox == null:
		push_error("ERROR: Falta SwordHitbox como hijo directo del Player.")
		return

	if sword_collision == null:
		push_error("ERROR: Falta CollisionShape2D dentro de SwordHitbox.")
		return

	sword_hitbox.monitoring = false
	sword_collision.disabled = true

	if not sword_hitbox.body_entered.is_connected(_on_sword_hitbox_body_entered):
		sword_hitbox.body_entered.connect(_on_sword_hitbox_body_entered)

	if not player_sprite.frame_changed.is_connected(_on_player_sprite_frame_changed):
		player_sprite.frame_changed.connect(_on_player_sprite_frame_changed)

	if not player_sprite.animation_finished.is_connected(_on_player_sprite_animation_finished):
		player_sprite.animation_finished.connect(_on_player_sprite_animation_finished)


func _input(event: InputEvent) -> void:
	if mode != Mode.USER_CONTROLLED:
		return

	if is_attacking:
		return

	if event.is_action_pressed("throw") and not event.is_echo():
		start_sword_attack()


func start_sword_attack() -> void:
	if mode != Mode.USER_CONTROLLED:
		return

	if is_attacking:
		return

	is_attacking = true
	sword_can_damage = true

	_update_last_attack_direction()
	_update_sword_hitbox_position()

	if player_sprite.sprite_frames != null and player_sprite.sprite_frames.has_animation("attack_01"):
		player_sprite.play("attack_01")
	else:
		_enable_sword_hitbox()

	await get_tree().create_timer(sword_attack_duration).timeout

	if is_attacking:
		_finish_sword_attack()


func _update_last_attack_direction() -> void:
	var input_direction := Vector2.ZERO

	if Input.is_action_pressed("ui_right"):
		input_direction.x += 1

	if Input.is_action_pressed("ui_left"):
		input_direction.x -= 1

	if Input.is_action_pressed("ui_down"):
		input_direction.y += 1

	if Input.is_action_pressed("ui_up"):
		input_direction.y -= 1

	if input_direction != Vector2.ZERO:
		last_attack_direction = input_direction.normalized()
	elif velocity != Vector2.ZERO:
		last_attack_direction = velocity.normalized()


func _update_sword_hitbox_position() -> void:
	if sword_hitbox == null:
		return

	if abs(last_attack_direction.x) > abs(last_attack_direction.y):
		if last_attack_direction.x > 0:
			sword_hitbox.position = Vector2(38, 0)
		else:
			sword_hitbox.position = Vector2(-38, 0)
	else:
		if last_attack_direction.y > 0:
			sword_hitbox.position = Vector2(0, 38)
		else:
			sword_hitbox.position = Vector2(0, -38)


func _enable_sword_hitbox() -> void:
	if sword_hitbox == null or sword_collision == null:
		return

	sword_hitbox.monitoring = true
	sword_collision.set_deferred("disabled", false)


func _disable_sword_hitbox() -> void:
	if sword_hitbox == null or sword_collision == null:
		return

	sword_hitbox.monitoring = false
	sword_collision.set_deferred("disabled", true)


func _on_player_sprite_frame_changed() -> void:
	if not is_attacking:
		return

	if player_sprite.animation != "attack_01" and player_sprite.animation != "attack_02":
		return

	if player_sprite.frame >= sword_active_frame_start and player_sprite.frame <= sword_active_frame_end:
		_enable_sword_hitbox()
	else:
		_disable_sword_hitbox()


func _on_player_sprite_animation_finished() -> void:
	if not is_attacking:
		return

	if player_sprite.animation == "attack_01" or player_sprite.animation == "attack_02":
		_finish_sword_attack()


func _finish_sword_attack() -> void:
	if not is_attacking:
		return

	_disable_sword_hitbox()

	is_attacking = false
	sword_can_damage = true

	if velocity == Vector2.ZERO:
		if player_sprite.sprite_frames != null and player_sprite.sprite_frames.has_animation("idle"):
			player_sprite.play("idle")


func _on_sword_hitbox_body_entered(body: Node) -> void:
	if not is_attacking:
		return

	if not sword_can_damage:
		return

	if body.is_in_group("boss"):
		print("Golpeaste al jefe con la espada")

		if body.has_method("take_damage"):
			body.take_damage(sword_damage)

		sword_can_damage = false


func take_damage(amount: int) -> void:
	if mode == Mode.DEFEATED:
		return

	current_health -= amount
	current_health = clamp(current_health, 0, max_health)

	print("Jugador recibió daño: ", amount)
	print("Vida del jugador: ", current_health)

	health_changed.emit(current_health, max_health)

	if current_health <= 0:
		defeat()
