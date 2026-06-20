extends CharacterBody2D

@export var move_speed: float = 95.0
@export var patrol_offset: Vector2 = Vector2(256, 0)
@export var player_reset_position: Vector2 = Vector2(-1760, -1760)

@onready var sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var danger_area: Area2D = %DangerArea

var _start_position: Vector2
var _end_position: Vector2
var _moving_to_end := true


func _ready() -> void:
	_start_position = global_position
	_end_position = _start_position + patrol_offset

	var callback := Callable(self, "_on_danger_area_body_entered")
	if not danger_area.body_entered.is_connected(callback):
		danger_area.body_entered.connect(callback)

	_update_animation()


func _physics_process(delta: float) -> void:
	if _start_position.distance_squared_to(_end_position) <= 1.0:
		velocity = Vector2.ZERO
		return

	var target := _end_position if _moving_to_end else _start_position
	var to_target := target - global_position

	if to_target.length() <= 4.0:
		_moving_to_end = not _moving_to_end
		target = _end_position if _moving_to_end else _start_position
		to_target = target - global_position

	var motion := to_target.normalized() * move_speed * delta
	if motion.length_squared() >= to_target.length_squared():
		global_position = target
		_moving_to_end = not _moving_to_end
		velocity = Vector2.ZERO
		_update_animation()
		return

	velocity = motion / delta
	_update_animation()
	var collision := move_and_collide(motion)
	if collision:
		_moving_to_end = not _moving_to_end


func _update_animation() -> void:
	if absf(velocity.y) > absf(velocity.x):
		sprite.flip_h = false
		var animation_name := &"walk_up"
		if velocity.y > 0.0:
			animation_name = &"walk_down"
		sprite.play(animation_name)
	else:
		sprite.flip_h = velocity.x > 0.0
		sprite.play(&"walk_side")


func _on_danger_area_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	call_deferred("_reset_player", body)


func _reset_player(body: Node2D) -> void:
	if not is_instance_valid(body):
		return

	body.global_position = player_reset_position
	if body is CharacterBody2D:
		body.velocity = Vector2.ZERO
