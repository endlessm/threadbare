@tool
class_name Guard extends CharacterBody2D

signal player_detected(player)

enum LookAtSide {
	LEFT = -1,
	RIGHT = 1,
}
@export var start_looking_at_side: LookAtSide = LookAtSide.LEFT :
	set(new_value):
		start_looking_at_side = new_value
		_update_direction(start_looking_at_side)
@export var patrol_path: Path2D
@export var wait_time: float = 1.0
var wait_time_left: float = 0.0
@export var move_speed: float = 100.0
@export_category("Debug")
@export var move_while_in_editor: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionShape

var current_point: int = 0
var is_moving: bool = true
var going_in_reverse: bool = false
var being_alerted: bool = false

enum State { Moving, Waiting, Alerted }

var state = State.Waiting

func _ready():
	if Engine.is_editor_hint():
		return
	if patrol_path:
		global_position = _patrol_point_position(0)
	detection_area.body_entered.connect(_on_body_entered)

func _process(delta):
	if Engine.is_editor_hint() and not move_while_in_editor:
		return
	match state:
		State.Moving:
			var target_position = _patrol_point_position(current_point)
			var direction = global_position.direction_to(target_position)
			velocity = direction * move_speed

			if detection_area and not velocity.is_zero_approx():
				var target_detection_area_rotation = velocity.angle()
				detection_area.rotation = move_toward(
					detection_area.rotation,
					target_detection_area_rotation,
					delta * 20.0
				)
			_update_direction(direction.x)
			move_and_slide()
			

			if global_position.distance_to(target_position) < move_speed * delta:
				state = State.Waiting
				wait_time_left = wait_time

		State.Waiting:
			wait_time_left -= delta
			if wait_time_left < 0.0 and patrol_path:
				state = State.Moving
				_move_to_next_point()
		
		State.Alerted:
			pass
	
	_update_animation()

func _update_animation():
	match state:
		State.Moving:
			sprite.play("walk")
		State.Waiting:
			sprite.play("idle")
		State.Alerted:
			if being_alerted:
				sprite.play("alerted")
			else:
				sprite.play("idle")

func _move_to_next_point():
	var at_last_point: bool = current_point == (_amount_of_patrol_points() - 1)
	var at_first_point: bool = current_point == 0

	if at_last_point and _is_patrol_path_closed():
		current_point = 1
	elif at_last_point:
		going_in_reverse = true
		current_point = (current_point - 1) % _amount_of_patrol_points()
	elif at_first_point and going_in_reverse:
		going_in_reverse = false
		current_point = (current_point + 1) % _amount_of_patrol_points()
	elif going_in_reverse:
		current_point = (current_point - 1) % _amount_of_patrol_points()
	else:
		current_point = (current_point + 1) % _amount_of_patrol_points()

func _update_direction(x_direction: float):
	if is_zero_approx(x_direction):
		return

	if sprite:
		sprite.flip_h = x_direction < 0

func _on_body_entered(body):
	state = State.Alerted
	player_detected.emit(body)
	%ExclamationMark.visible = true
	being_alerted = false
	await create_tween().tween_property(%ExclamationMark, "scale", Vector2.ONE * 2.0, 0.3).set_trans(Tween.TRANS_ELASTIC).finished
	being_alerted = true
	

func _patrol_point_position(point_idx: int) -> Vector2:
	var local_point_position = patrol_path.curve.get_point_position(point_idx)
	return patrol_path.to_global(local_point_position)

func _amount_of_patrol_points() -> int:
	return patrol_path.curve.point_count

func _is_patrol_path_closed() -> bool:
	if not patrol_path:
		return false
	
	var curve := patrol_path.curve
	if curve.point_count < 3:
		return false

	var first_point_position := curve.get_point_position(0)
	var last_point_position := curve.get_point_position(curve.point_count - 1)
	
	return first_point_position.is_equal_approx(last_point_position)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_EDITOR_PRE_SAVE:
			current_point = 0
			_update_direction(start_looking_at_side)
			if patrol_path:
				global_position = _patrol_point_position(0)
