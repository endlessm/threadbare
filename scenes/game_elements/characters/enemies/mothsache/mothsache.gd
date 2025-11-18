# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name Mothsache
extends CharacterBody2D
## Enemy type that wanders erratically and chases the player upon detection.

enum State {
	IDLE,
	WANDERING,
	RETURNING,
	DETECTING,
	ALERTED,
	ATTACKING,
}

const ErraticWalkBehaviorScript = preload(
	"res://scenes/game_logic/walk_behaviors/erratic_walk_behavior.gd"
)
const FAST_DETECT_TIME: float = 0.2
const MAX_SPEED: float = 300

@export var time_to_detect_player: float = 1.2
@export var instantly_detect: bool = true

@export_category("Movement")
@export var chase_speed: float = 250
@export_range(1.0, 10.0, 0.5, "suffix:s") var idle_wait_time: float = 3.0
@export_range(1.0, 30.0, 0.5, "suffix:s") var wandering_duration: float = 10.0
@export var burst_deceleration: float = 400.0

@export_category("Sounds")
@export var alert_sound_stream: AudioStream:
	set = _set_alert_sound_stream

var state: State = State.IDLE:
	set = _set_state
var _awareness: float = 0.0
var _player: CharacterBody2D = null
var _initial_position: Vector2
var _return_direction: Vector2
var _return_start_position: Vector2
var _stuck_timer: float = 0.0
var _max_stuck_time: float = 2.0
var _reached_max_speed: bool = false
var _current_chase_speed: float = 0.0
var _can_burst: bool = false
var _previous_non_detecting_state: State = State.IDLE

@onready var detection_area: Area2D = $Area2D
@onready var awareness_bar: TextureProgressBar = $PlayerAwareness
@onready var erratic_walk_behavior: Node = %ErraticWalkBehavior
@onready var behavior_timer: Timer = %BehaviorTimer
@onready var debug_label: Label = %DebugInfo
@onready var attack_radius: Area2D = $AttackRadius
@onready var _alert_sound: AudioStreamPlayer = $Sounds/AlertSound


func _ready() -> void:
	awareness_bar.max_value = time_to_detect_player
	awareness_bar.value = 0.0
	awareness_bar.visible = false
	_set_alert_sound_stream(alert_sound_stream)
	_initial_position = global_position

	if not detection_area.body_entered.is_connected(_on_detection_area_body_entered):
		detection_area.body_entered.connect(_on_detection_area_body_entered)
	if not detection_area.body_exited.is_connected(_on_detection_area_body_exited):
		detection_area.body_exited.connect(_on_detection_area_body_exited)
	if not behavior_timer.timeout.is_connected(_on_BehaviorTimer_timeout):
		behavior_timer.timeout.connect(_on_BehaviorTimer_timeout)
	if not attack_radius.body_entered.is_connected(_on_attack_radius_body_entered):
		attack_radius.body_entered.connect(_on_attack_radius_body_entered)

	state = State.IDLE


func _physics_process(delta: float) -> void:
	if state != State.ALERTED:
		_update_detection(delta)

	_process_movement(delta)

	var was_colliding: bool = is_on_wall()
	move_and_slide()
	var is_colliding: bool = is_on_wall()

	if state == State.RETURNING and is_colliding and not was_colliding:
		var angle_offset: float = PI / 4.0
		if randf() < 0.5:
			angle_offset *= -1

		_return_direction = _return_direction.rotated(angle_offset)
	elif state == State.RETURNING and not is_colliding:
		_return_direction = global_position.direction_to(_initial_position)

	_check_if_stuck(delta)
	_update_debug_info()


func _process_movement(delta: float) -> void:
	var walk_speed: float = 0.0
	if erratic_walk_behavior.get("speeds"):
		walk_speed = (erratic_walk_behavior as ErraticWalkBehavior).speeds.walk_speed

	match state:
		State.IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, 500.0 * delta)
			erratic_walk_behavior.process_mode = Node.PROCESS_MODE_DISABLED
			_reached_max_speed = false

		State.WANDERING:
			erratic_walk_behavior.process_mode = Node.PROCESS_MODE_INHERIT
			(erratic_walk_behavior as ErraticWalkBehavior)._physics_process(delta)
			velocity = velocity.lerp(
				(erratic_walk_behavior as ErraticWalkBehavior).direction * walk_speed, 0.1
			)
			_reached_max_speed = false

		State.RETURNING:
			erratic_walk_behavior.process_mode = Node.PROCESS_MODE_DISABLED
			velocity = _return_direction * walk_speed
			_reached_max_speed = false

			if global_position.distance_to(_initial_position) < 5.0:
				global_position = _initial_position
				state = State.IDLE

		State.DETECTING:
			if is_instance_valid(_player):
				var direction_to_player: Vector2 = global_position.direction_to(
					_player.global_position
				)
				velocity = velocity.lerp(direction_to_player * walk_speed, 0.15)
			else:
				velocity = velocity.move_toward(Vector2.ZERO, 500.0 * delta)
			_reached_max_speed = false

		State.ALERTED:
			if is_instance_valid(_player):
				var direction_to_player: Vector2 = global_position.direction_to(
					_player.global_position
				)

				if _current_chase_speed > chase_speed:
					_current_chase_speed = move_toward(
						_current_chase_speed, chase_speed, burst_deceleration * delta
					)

				velocity = direction_to_player * _current_chase_speed
				_reached_max_speed = true
			else:
				_reached_max_speed = false

		State.ATTACKING:
			velocity = Vector2.ZERO
			_reached_max_speed = false


func _check_if_stuck(delta: float) -> void:
	if state == State.RETURNING:
		var distance_moved: float = global_position.distance_to(_return_start_position)

		if distance_moved < 10.0:
			_stuck_timer += delta
		else:
			_stuck_timer = 0.0
			_return_start_position = global_position

		if _stuck_timer >= _max_stuck_time:
			state = State.WANDERING
			_stuck_timer = 0.0


func _update_detection(delta: float) -> void:
	var target_awareness: float = 0.0
	var awareness_speed: float = 1.0

	if is_instance_valid(_player):
		target_awareness = time_to_detect_player

		if state == State.IDLE or state == State.WANDERING:
			_previous_non_detecting_state = state

		state = State.DETECTING

		if instantly_detect:
			awareness_speed = time_to_detect_player / FAST_DETECT_TIME
	else:
		target_awareness = 0.0

	if _awareness < target_awareness:
		_awareness = move_toward(_awareness, target_awareness, delta * awareness_speed)
	else:
		_awareness = move_toward(_awareness, target_awareness, delta * 1.0)

	awareness_bar.value = _awareness
	awareness_bar.visible = awareness_bar.ratio > 0.0
	awareness_bar.modulate.a = clamp(awareness_bar.ratio, 0.5, 1.0)

	if _awareness >= time_to_detect_player:
		state = State.ALERTED
	elif (
		_awareness == 0.0
		and state != State.IDLE
		and state != State.WANDERING
		and state != State.RETURNING
	):
		state = State.WANDERING


func _set_state(new_state: State) -> void:
	if state == new_state:
		return

	state = new_state
	behavior_timer.stop()

	match state:
		State.IDLE:
			_alert_sound.stop()
			behavior_timer.start(idle_wait_time)
			awareness_bar.tint_progress = Color.WHITE
			_reached_max_speed = false
			_can_burst = true

		State.WANDERING:
			behavior_timer.start(wandering_duration)
			(erratic_walk_behavior as ErraticWalkBehavior)._update_direction()
			_reached_max_speed = false
			_can_burst = false

		State.RETURNING:
			_return_direction = global_position.direction_to(_initial_position)
			_return_start_position = global_position
			_stuck_timer = 0.0
			_reached_max_speed = false
			_can_burst = true

		State.DETECTING:
			if not _alert_sound.playing:
				_alert_sound.play()
			awareness_bar.tint_progress = Color.WHITE
			_reached_max_speed = false

		State.ALERTED:
			if not _alert_sound.playing:
				_alert_sound.play()
			awareness_bar.value = awareness_bar.max_value
			awareness_bar.tint_progress = Color.RED
			awareness_bar.modulate.a = 1.0
			_reached_max_speed = true

			if is_instance_valid(_player):
				if _can_burst:
					_current_chase_speed = chase_speed * 2.0
					_can_burst = false
				else:
					_current_chase_speed = chase_speed

				var direction_to_player: Vector2 = global_position.direction_to(
					_player.global_position
				)
				velocity = direction_to_player * _current_chase_speed

		State.ATTACKING:
			pass


func _set_alert_sound_stream(new_value: AudioStream) -> void:
	alert_sound_stream = new_value
	if not is_node_ready():
		await ready
	_alert_sound.stream = new_value


func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player = body
		_awareness = 0.0
		if state != State.ALERTED:
			pass


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player = null
		if state == State.DETECTING or state == State.ALERTED:
			if _previous_non_detecting_state == State.WANDERING:
				state = State.WANDERING
			else:
				state = State.RETURNING


func _on_BehaviorTimer_timeout() -> void:
	match state:
		State.IDLE:
			state = State.WANDERING
		State.WANDERING:
			state = State.RETURNING


func _on_attack_radius_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		state = State.ATTACKING
		if body.has_method("defeat"):
			var player: Node2D = body
			player.defeat(true)


func _update_debug_info() -> void:
	if not is_instance_valid(debug_label):
		return

	var debug_text: String = "pos: (%.1f, %.1f)\n" % [global_position.x, global_position.y]
	debug_text += "state: %s" % State.keys()[state].to_lower()

	if behavior_timer.time_left > 0:
		debug_text += " (%.1fs)" % behavior_timer.time_left

	debug_text += "\n"

	var current_speed: float = velocity.length()
	var target_speed: float = 0.0
	var speed_label: String = "n/a"

	if state == State.ALERTED:
		target_speed = chase_speed
		speed_label = "chase"

		if _current_chase_speed > chase_speed + 5:
			debug_text += "current speed: %d\n" % current_speed
			debug_text += "burst speed: %d (decaying)\n" % _current_chase_speed
			debug_text += "target speed: %d (%s) [burst!]" % [target_speed, speed_label]
		else:
			debug_text += "current speed: %d\n" % current_speed
			debug_text += "target speed: %d (%s)" % [target_speed, speed_label]

	elif state == State.WANDERING or state == State.RETURNING:
		if erratic_walk_behavior.get("speeds"):
			target_speed = (erratic_walk_behavior as ErraticWalkBehavior).speeds.walk_speed
			speed_label = "walk"
		debug_text += "current speed: %d\n" % current_speed
		debug_text += "target speed: %d (%s)" % [target_speed, speed_label]

	elif state == State.ATTACKING:
		debug_text += "current speed: 0\n"
		debug_text += "target speed: 0 (ATTACKING)"

	else:
		debug_text += "current speed: %d\n" % current_speed
		debug_text += "target speed: 0 (idle)"

	debug_label.text = debug_text
