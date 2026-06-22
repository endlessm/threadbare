# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name Guard extends CharacterBody2D

signal player_detected(player: Node2D)

static var game_started: bool = false
static var max_chasers: int = 2  # cuántos guardias pueden perseguir a la vez (ajustable 1-3)
static var _current_chasers: int = 0

@export_range(20, 600, 5, "or_greater", "suffix:m/s") var chase_speed: float = 380.0
@export_range(50, 500, 10) var chase_distance: float = 300.0
@export_range(0.5, 5.0, 0.5) var wander_wait: float = 2.0
@export_range(50, 800, 10) var wander_distance: float = 250.0

enum State {
	PATROLLING,
	DETECTING,
	ALERTED,
	INVESTIGATING,
	RETURNING,
}

const DEFAULT_SPRITE_FRAMES = preload("uid://ovu5wqo15s5g")

@export_category("Appearance")
@export var sprite_frames: SpriteFrames = DEFAULT_SPRITE_FRAMES:
	set = _set_sprite_frames
@export_category("Sounds")
@export var alerted_sound_stream: AudioStream:
	set = _set_alerted_sound_stream
@export var footsteps_sound_stream: AudioStream:
	set = _set_footsteps_sound_stream
@export var idle_sound_stream: AudioStream:
	set = _set_idle_sound_stream
@export var alert_others_sound_stream: AudioStream:
	set = _set_alert_other_sound_stream

@export_range(0, 5, 0.1, "or_greater", "suffix:s") var wait_time: float = 1.0
@export_range(20, 300, 5, "or_greater", "or_less", "suffix:m/s") var move_speed: float = 100.0

@export_category("Player Detection")
@export var player_instantly_detected_on_sight: bool = false
@export_range(0.1, 5, 0.1, "or_greater", "suffix:s") var time_to_detect_player: float = 1.0
@export_range(0.1, 5, 0.1, "or_greater", "or_less") var detection_area_scale: float = 0.4:
	set(new_value):
		detection_area_scale = new_value
		if detection_area:
			detection_area.scale = Vector2.ONE * detection_area_scale

@export_category("Debug")
@export var move_while_in_editor: bool = false
@export var show_debug_info: bool = false

var last_seen_position: Vector2
var breadcrumbs: Array[Vector2] = []
var state: State = State.PATROLLING:
	set = _set_state

var _player: Node2D
var _is_chasing: bool = false
var _wander_timer: float = 0.0

@onready var detection_area: Area2D = %DetectionArea
@onready var player_awareness: TextureProgressBar = %PlayerAwareness
@onready var sight_ray_cast: RayCast2D = %SightRayCast
@onready var debug_info: Label = %DebugInfo
@onready var character_animation_player_behavior: CharacterAnimationPlayerBehavior = %CharacterAnimationPlayerBehavior
@onready var guard_movement: GuardMovement = %GuardMovement
@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var _alert_sound: AudioStreamPlayer = %AlertSound
@onready var _foot_sound: AudioStreamPlayer2D = %FootSound
@onready var _fire_sound: AudioStreamPlayer2D = %FireSound
@onready var _torch_hit_sound: AudioStreamPlayer2D = %TorchHitSound


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray
	if not sprite_frames:
		warnings.push_back("sprite_frames must be set.")
	for required_animation: StringName in [&"alerted", &"idle", &"walk"]:
		if sprite_frames and not sprite_frames.has_animation(required_animation):
			warnings.push_back(
				"sprite_frames is missing the following animation: %s" % required_animation
			)
	return warnings


func _ready() -> void:
	if not Engine.is_editor_hint():
		if player_awareness:
			player_awareness.max_value = time_to_detect_player
			player_awareness.value = 0.0

	_set_sprite_frames(sprite_frames)

	if detection_area:
		detection_area.scale = Vector2.ONE * detection_area_scale

	guard_movement.destination_reached.connect(self._on_destination_reached)
	guard_movement.still_time_finished.connect(self._on_still_time_finished)
	guard_movement.path_blocked.connect(self._on_path_blocked)


func _process(delta: float) -> void:
	_update_debug_info()

	if Engine.is_editor_hint() and not move_while_in_editor:
		return

	if not game_started:
		return

	_process_state(delta)
	guard_movement.move()

	if state != State.ALERTED:
		_update_player_awareness(delta)

	_update_animation()


## Maneja el movimiento según el estado. La lógica de SALIR de ALERTED
## (liberar cupo de chasers, etc.) vive únicamente aquí, no en _set_state,
## para evitar restar el contador dos veces.
func _process_state(delta: float) -> void:
	match state:
		State.PATROLLING:
			_wander(delta)
		State.INVESTIGATING:
			guard_movement.set_destination(last_seen_position)
		State.RETURNING:
			if not breadcrumbs.is_empty():
				var target_position: Vector2 = breadcrumbs.back()
				guard_movement.set_destination(target_position)
			else:
				state = State.PATROLLING
		State.ALERTED:
			if _player and is_instance_valid(_player) and _player is Player:
				var distance := global_position.distance_to(_player.global_position)
				if distance > chase_distance:
					_player = null
					_is_chasing = false
					_stop_camera_shake()
					move_speed = 100.0
					_current_chasers = max(0, _current_chasers - 1)
					state = State.INVESTIGATING
				elif distance < 25.0:
					_player.defeat()
				else:
					move_speed = chase_speed
					guard_movement.set_destination(_player.global_position)
			else:
				_is_chasing = false
				_stop_camera_shake()
				move_speed = 100.0
				_current_chasers = max(0, _current_chasers - 1)
				state = State.INVESTIGATING


## Camina libremente: cada vez que llega a destino o se traba, espera un
## poco y elige un punto aleatorio cerca para caminar hacia allá.
func _wander(delta: float) -> void:
	if _wander_timer > 0.0:
		_wander_timer -= delta
		guard_movement.stop_moving()
		return

	if guard_movement.has_reached_destination():
		_wander_timer = wander_wait
		var angle := randf() * TAU
		var radius := randf_range(wander_distance * 0.3, wander_distance)
		var new_target := global_position + Vector2(cos(angle), sin(angle)) * radius
		guard_movement.set_destination(new_target)


func _update_player_awareness(delta: float) -> void:
	var player_in_sight := _player and not _is_sight_to_point_blocked(_player.global_position)

	player_awareness.value = move_toward(
		player_awareness.value, player_awareness.max_value if player_in_sight else 0.0, delta
	)
	player_awareness.visible = player_awareness.ratio > 0.0
	player_awareness.modulate.a = clamp(player_awareness.ratio, 0.5, 1.0)

	if player_awareness.ratio >= 1.0 and _current_chasers < max_chasers:
		_current_chasers += 1
		state = State.ALERTED
		player_detected.emit(_player)
	# Si no hay cupo, se queda con el awareness lleno pero no entra en
	# ALERTED. Apenas otro guardia libere su cupo, el siguiente _process
	# de este guardia (que sigue viendo al jugador con ratio = 1.0) lo
	# activará automáticamente.


func _update_animation() -> void:
	if state == State.ALERTED:
		if not velocity.is_zero_approx():
			animation_player.play(&"walk")
		return
	if velocity.is_zero_approx():
		animation_player.play(&"idle")
	else:
		animation_player.play(&"walk")


func _shake_camera() -> void:
	var camera := get_viewport().get_camera_2d()
	if not camera:
		return
	if camera.has_meta("shake_tween"):
		return
	var tween := create_tween().set_loops()
	tween.tween_property(camera, "offset", Vector2(4, 0), 0.05)
	tween.tween_property(camera, "offset", Vector2(-4, 0), 0.05)
	tween.tween_property(camera, "offset", Vector2(0, 3), 0.05)
	tween.tween_property(camera, "offset", Vector2(0, -3), 0.05)
	camera.set_meta("shake_tween", tween)


func _stop_camera_shake() -> void:
	var camera := get_viewport().get_camera_2d()
	if not camera:
		return
	if camera.has_meta("shake_tween"):
		var tween = camera.get_meta("shake_tween")
		if tween:
			tween.kill()
		camera.remove_meta("shake_tween")
	camera.offset = Vector2.ZERO


func _update_debug_info() -> void:
	debug_info.visible = show_debug_info
	if not debug_info.visible:
		return
	debug_info.text = ""
	debug_property("position")
	debug_value("state", State.keys()[state])
	debug_value("time left", "%.2f" % guard_movement.still_time_left_in_seconds)
	debug_value("target point", guard_movement.destination)


func _on_destination_reached() -> void:
	match state:
		State.INVESTIGATING:
			guard_movement.wait_seconds(wait_time)
		State.RETURNING:
			breadcrumbs.pop_back()


func _on_still_time_finished() -> void:
	match state:
		State.INVESTIGATING:
			state = State.RETURNING


func _on_path_blocked() -> void:
	match state:
		State.PATROLLING:
			_wander_timer = 0.0
			guard_movement.stop_moving()
		State.INVESTIGATING:
			state = State.RETURNING
		State.RETURNING:
			if not breadcrumbs.is_empty():
				breadcrumbs.pop_back()


## Solo maneja efectos visuales/sonoros de ENTRAR a cada estado, NO lógica
## de salida (eso vive en _process_state para no duplicar la resta del
## contador _current_chasers).
func _set_state(new_state: State) -> void:
	if state == new_state:
		return

	state = new_state

	match state:
		State.DETECTING:
			if not _alert_sound.playing:
				_alert_sound.play()
		State.ALERTED:
			character_animation_player_behavior.process_mode = Node.PROCESS_MODE_DISABLED
			if not _alert_sound.playing:
				_alert_sound.play()
			animation_player.play(&"alerted")
			player_awareness.ratio = 1.0
			player_awareness.tint_progress = Color.RED
			player_awareness.visible = true
			if _player and is_instance_valid(_player):
				_shake_camera()
		State.INVESTIGATING:
			character_animation_player_behavior.process_mode = Node.PROCESS_MODE_INHERIT
			guard_movement.start_moving_now()
			breadcrumbs.push_back(global_position)
			_stop_camera_shake()
			move_speed = 100.0
		State.PATROLLING:
			move_speed = 100.0


func debug_property(property_name: String) -> void:
	debug_value(property_name, get(property_name))


func debug_value(value_name: String, value: Variant) -> void:
	debug_info.text += "%s: %s\n" % [value_name, value]


func _is_sight_to_point_blocked(point_position: Vector2) -> bool:
	sight_ray_cast.target_position = sight_ray_cast.to_local(point_position)
	sight_ray_cast.force_raycast_update()
	return sight_ray_cast.is_colliding()


func _set_sprite_frames(new_sprite_frames: SpriteFrames) -> void:
	sprite_frames = new_sprite_frames
	if not is_node_ready():
		return
	animated_sprite_2d.sprite_frames = sprite_frames
	update_configuration_warnings()


func _set_alerted_sound_stream(new_value: AudioStream) -> void:
	alerted_sound_stream = new_value
	if not is_node_ready():
		await ready
	_alert_sound.stream = new_value


func _set_footsteps_sound_stream(new_value: AudioStream) -> void:
	footsteps_sound_stream = new_value
	if not is_node_ready():
		await ready
	_foot_sound.stream = new_value


func _set_idle_sound_stream(new_value: AudioStream) -> void:
	idle_sound_stream = new_value
	if not is_node_ready():
		await ready
	_fire_sound.stream = new_value


func _set_alert_other_sound_stream(new_value: AudioStream) -> void:
	alert_others_sound_stream = new_value
	if not is_node_ready():
		await ready
	_torch_hit_sound.stream = new_value


func _on_instant_detection_area_body_entered(body: Node2D) -> void:
	state = State.ALERTED
	player_detected.emit(body)


func _on_detection_area_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	_player = body
	if _is_sight_to_point_blocked(body.global_position):
		return
	if player_instantly_detected_on_sight:
		state = State.ALERTED
		player_detected.emit(_player)
	else:
		state = State.DETECTING


func _on_detection_area_body_exited(body: Node2D) -> void:
	if not body is Player:
		return
	last_seen_position = body.global_position
	if state == State.DETECTING:
		_player = null
		guard_movement.stop_moving()
		state = State.INVESTIGATING
	elif state == State.ALERTED:
		pass
