@tool
class_name Guard extends CharacterBody2D

signal player_detected(player)

@export_category("Patrol")
@export var patrol_path: Path2D
@export var wait_time: float = 1.0
@export var move_speed: float = 100.0
@export_category("Player Detection")
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
@onready var guard_movement: GuardMovement = $GuardMovement

var current_point: int = 0
var going_in_reverse: bool = false
var calling_for_backup_animation_playing: bool = false
var last_seen_position: Vector2
var breadcrumbs: Array[Vector2] = []

enum State {
	## Going along the path
	Patroling,
	## Player is in sight
	Detecting,
	## Player was detected and the stealth mission failed
	Alerted,
	## Player was in sight, going to the last point where the player was seen
	Investigating,
	## Lost track of player, going back to the path
	Returning
	}

var state = State.Patroling :
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
	guard_movement.destination_reached.connect(self._on_destination_reached)
	guard_movement.still_time_finished.connect(self._on_still_time_finished)

func _process(delta):
	if Engine.is_editor_hint() and not move_while_in_editor:
		return

	match state:
		State.Patroling:
			var target_position = _patrol_point_position(current_point)
			guard_movement.set_destination(target_position)
		State.Investigating:
			pass
		State.Detecting:
			guard_movement.stop_moving()
			if not _player_in_sight():
				_change_to(State.Investigating)
		State.Returning:
			var target_position = breadcrumbs.back()
			guard_movement.set_destination(target_position)
		State.Alerted:
			guard_movement.stop_moving()

	var player_in_sight = _player_in_sight()
	var is_detecting_player = !!player_in_sight or state == State.Alerted

	if player_in_sight:
		last_seen_position = player_in_sight.global_position

	if instant_detection_area.has_overlapping_bodies() or\
		player_awareness.ratio >= 1.0 or\
		(is_detecting_player and player_instantly_loses_on_sight):
		_change_to(State.Alerted)
	elif is_detecting_player:
		_change_to(State.Detecting)

	_update_player_awareness(is_detecting_player, delta)
	_update_detection_area(delta)
	_update_direction()
	_update_animation()

	debug_info.text = ""
	debug_property("state")
	debug_property("going_in_reverse")
	debug_property("current_point")
	debug_info.text += "%s: %s\n" % ["time left", guard_movement.still_time_left_in_seconds]
	debug_info.text += "%s: %s\n" % ["target point", guard_movement.destination]

func _update_player_awareness(is_detecting_player: bool, delta: float):
	player_awareness.value = move_toward(
		player_awareness.value,
		player_awareness.max_value if is_detecting_player else 0.0,
		delta
	)
	player_awareness.visible = player_awareness.ratio > 0.0
	player_awareness.modulate.a = min(player_awareness.ratio + 0.5, 1.0) if player_awareness.ratio > 0.0 else 0.0

func _on_destination_reached():
	match state:
		State.Patroling:
			_advance_target_patrol_point()
			guard_movement.wait_seconds(wait_time)
		State.Investigating:
			guard_movement.wait_seconds(wait_time)
		State.Returning:
			breadcrumbs.pop_back()
			if breadcrumbs.is_empty():
				_change_to(State.Patroling)

func _on_still_time_finished():
	match state:
		State.Investigating:
			_change_to(State.Returning)


func _change_to(next_state):
	if next_state == state:
		return
	
	if name == "Guard" and next_state == State.Patroling:
		pass
	
	state = next_state
	_on_enter_state(state)

func _on_enter_state(state):
	match state:
		State.Alerted:
			player_detected.emit(_player_in_sight())
			player_awareness.ratio = 1.0
			player_awareness.tint_progress = Color.RED
			await get_tree().create_timer(0.4).timeout
			calling_for_backup_animation_playing = true
		State.Investigating:
			guard_movement.start_moving_towards(last_seen_position)
			breadcrumbs.push_back(global_position)

func debug_property(value_name):
	debug_value(value_name, get(value_name))

func debug_value(value_name, value):
	debug_info.text += "%s: %s\n" % [value_name, value]

func _update_animation():
	if state == State.Alerted and calling_for_backup_animation_playing:
		sprite.play("alerted")
	elif velocity.is_zero_approx():
		sprite.play("idle")
	else:
		sprite.play("walk")

func _advance_target_patrol_point():
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

func _update_detection_area(delta):
	if velocity.is_zero_approx():
		return
	
	var target_angle = velocity.angle()
	detection_area.rotation = rotate_toward(detection_area.rotation, target_angle, delta * 10.0)

func _update_direction():
	if is_zero_approx(velocity.x):
		return

	if sprite:
		sprite.flip_h = velocity.x < 0

func _point_in_sight(point_position: Vector2) -> bool:
	ray_cast_2d.target_position = ray_cast_2d.to_local(point_position)
	ray_cast_2d.force_raycast_update()
	return ray_cast_2d.is_colliding()

func _player_in_sight():
	if instant_detection_area.has_overlapping_bodies():
		return instant_detection_area.get_overlapping_bodies().front()

	if detection_area.has_overlapping_bodies():
		var player = detection_area.get_overlapping_bodies().front()

		if _point_in_sight(player.global_position):
			return null

		return player

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
			if patrol_path:
				global_position = _patrol_point_position(0)
