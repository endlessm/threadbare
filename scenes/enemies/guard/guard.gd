@tool
class_name Guard extends CharacterBody2D

signal player_sighted(player)
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
@export var time_to_detect_player_in_seconds: float = 1.0
@export var detection_area_scale: float = 1.0 :
	set(new_value):
		detection_area_scale = new_value
		if detection_area:
			detection_area.scale = Vector2.ONE * detection_area_scale
@export var player_instantly_loses_on_sight: bool = false

@export_category("Debug")
@export var move_while_in_editor: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionShape
@onready var player_awareness: TextureProgressBar = %PlayerAwareness
@onready var instant_detection_area: Area2D = $InstantDetectionArea
@onready var ray_cast_2d: RayCast2D = %SightRaycast
@onready var debug_info: Label = %DebugInfo


var current_point: int = 0
var is_moving: bool = true
var going_in_reverse: bool = false
var being_alerted: bool = false
var detection_alpha: float = 0.0
var last_seen_position: Vector2
var breadcrumbs: Array[Vector2] = []

enum State { Moving, Waiting, Detecting, Alerted, Investigating, Returning  }

var state = State.Waiting :
	set(new_state):
		state = new_state

func _ready():
	if Engine.is_editor_hint():
		return
	if patrol_path:
		global_position = _patrol_point_position(0)
	if player_awareness:
		player_awareness.max_value = time_to_detect_player_in_seconds
		player_awareness.value = 0.0

func _process(delta):
	if Engine.is_editor_hint() and not move_while_in_editor:
		return
	match state:
		State.Moving:
			var target_position = _patrol_point_position(current_point)
			var direction = global_position.direction_to(target_position)
			velocity = direction * move_speed

			var target_detection_area_rotation = velocity.angle()
			if detection_area and not velocity.is_zero_approx():
				
				detection_area.rotation = move_toward(
					detection_area.rotation,
					target_detection_area_rotation,
					delta * 5.0
				)
			_update_direction(direction.x)
			if not is_equal_approx(detection_area.rotation, target_detection_area_rotation):
				velocity = Vector2.ZERO
			move_and_slide()
			

			if _player_in_sight():
				last_seen_position = _player_in_sight().global_position
				change_to_detecting()
			elif global_position.distance_to(target_position) < move_speed * delta or (get_last_slide_collision() and get_last_slide_collision().get_travel().length() < 0.01):
				_move_to_next_point()
				state = State.Waiting
				wait_time_left = wait_time

		State.Waiting:
			velocity = Vector2.ZERO
			wait_time_left -= delta
			if _player_in_sight():
				last_seen_position = _player_in_sight().global_position
				change_to_detecting()
			elif wait_time_left < 0.0 and patrol_path:
				state = State.Moving

		State.Investigating:
			if global_position.distance_to(last_seen_position) > move_speed * delta:
				var direction = global_position.direction_to(last_seen_position)
				velocity = direction * move_speed
				move_and_slide()
				if _player_in_sight():
					last_seen_position = _player_in_sight().global_position
					change_to_detecting()
				if get_last_slide_collision() and get_last_slide_collision().get_travel().length() < 0.01:
					state = State.Returning
					wait_time_left = wait_time
			else:
				state = State.Returning
				wait_time_left = wait_time
		
		State.Detecting:
			if _player_in_sight() and player_awareness.ratio >= 1.0:
				change_to_alerted(_player_in_sight())
			if not _player_in_sight():
				breadcrumbs.push_back(global_position)
				state = State.Investigating

		State.Returning:
			wait_time_left -= delta
			if wait_time_left <= 0.0:
				var target_position = breadcrumbs.back()
				var direction = global_position.direction_to(target_position)
				velocity = direction * move_speed
				var target_detection_area_rotation = velocity.angle()

				if detection_area and not velocity.is_zero_approx():					
					detection_area.rotation = move_toward(
						detection_area.rotation,
						target_detection_area_rotation,
						delta * 5.0
					)
				_update_direction(direction.x)
				if not is_equal_approx(detection_area.rotation, target_detection_area_rotation):
					velocity = Vector2.ZERO
				move_and_slide()

				if _player_in_sight():
					last_seen_position = _player_in_sight().global_position
					change_to_detecting()
				elif global_position.distance_to(target_position) < move_speed * delta or (get_last_slide_collision() and get_last_slide_collision().get_travel().length() < 0.01):
					breadcrumbs.pop_back()
					if breadcrumbs.is_empty():
						state = State.Waiting
						wait_time_left = wait_time
			else:
				velocity = Vector2.ZERO

		State.Alerted:
			pass

	var is_detecting_enemy = !!_player_in_sight() or state == State.Alerted
	var target_player_awareness = player_awareness.max_value if is_detecting_enemy else 0.0
	player_awareness.value = move_toward(
		player_awareness.value,
		target_player_awareness,
		delta
	)
	var target_detection_alpha = 1.0 if is_detecting_enemy else 0.0
	detection_alpha = move_toward(detection_alpha, target_detection_alpha, delta * 5.0)
	player_awareness.modulate.a = detection_alpha
	if instant_detection_area.has_overlapping_bodies():
		change_to_alerted(instant_detection_area.get_overlapping_bodies().front())
	_update_animation()
	debug_info.text = ""
	debug_property("going_in_reverse")
	debug_property("current_point")

func debug_property(value_name):
	debug_value(value_name, get(value_name))

func debug_value(value_name, value):
	debug_info.text += "%s: %s\n" % [value_name, value]

func change_to_detecting():
	if player_instantly_loses_on_sight:
		change_to_alerted(detection_area.get_overlapping_bodies().front())
	else:
		state = State.Detecting
		%NoticedSomethingShakeVFX.start()
		create_tween().tween_property(%PlayerAwareness, "scale", Vector2.ONE, 0.5).from(Vector2.ONE * 0.001).set_trans(Tween.TRANS_ELASTIC)

func change_to_alerted(player):
	state = State.Alerted
	player_detected.emit(player)
	%PlayerAwareness.visible = true
	%PlayerAwareness.value = %PlayerAwareness.max_value
	being_alerted = false
	create_tween().tween_property(%PlayerAwareness, "tint_progress", Color.RED, 0.3).set_trans(Tween.TRANS_ELASTIC)
	await create_tween().tween_property(%PlayerAwareness, "scale", Vector2.ONE * 1.5, 0.3).set_trans(Tween.TRANS_ELASTIC).finished
	being_alerted = true

func _update_animation():
	if state == State.Alerted and being_alerted:
		sprite.play("alerted")
		return
	if velocity.is_zero_approx():
		sprite.play("idle")
	else:
		sprite.play("walk")


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

func _point_in_sight(point_position: Vector2) -> bool:
	ray_cast_2d.target_position = ray_cast_2d.to_local(point_position)
	ray_cast_2d.force_raycast_update()
	return ray_cast_2d.is_colliding()

func _player_in_sight():
	if detection_area.has_overlapping_bodies():
		var player = detection_area.get_overlapping_bodies().front()
		if _point_in_sight(player.global_position):
			return null
		return player
	else:
		return null

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
