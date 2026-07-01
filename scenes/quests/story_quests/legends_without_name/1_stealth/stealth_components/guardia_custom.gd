# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name GuardiaCustom extends CharacterBody2D
## Enemy type that patrols along a path and raises an alert if the player is detected.

## Emitted when the player is detected.
signal player_detected(player: Node2D)

enum State {
	PATROLLING,
	DETECTING,
	ALERTED,
	INVESTIGATING,
	RETURNING,
	CHASING,
	WANDERING,
}

const DEFAULT_SPRITE_FRAMES = preload("uid://ovu5wqo15s5g")

@export_category("Custom AI")
@export var es_acosador: bool = false
@export var solo_ronda_zona: bool = false

var posicion_inicial: Vector2

@export var radio_patrulla: float = 250.0:
	set(new_value):
		radio_patrulla = new_value
		queue_redraw()

# --- NUEVO: RADAR 360 ---
@export var radio_radar: float = 100.0:
	set(new_value):
		radio_radar = new_value
		queue_redraw()
# ------------------------

@export_category("Appearance")
@export var sprite_frames: SpriteFrames = DEFAULT_SPRITE_FRAMES:
	set = _set_sprite_frames
@export_category("Sounds")
@export var alerted_sound_stream: AudioStream:
	set = _set_alerted_sound_stream
@export_category("Sounds")
@export var footsteps_sound_stream: AudioStream:
	set = _set_footsteps_sound_stream
@export_category("Sounds")
@export var idle_sound_stream: AudioStream:
	set = _set_idle_sound_stream
@export_category("Sounds")
@export var alert_others_sound_stream: AudioStream:
	set = _set_alert_other_sound_stream

@export_category("Patrol")
@warning_ignore("unused_private_class_variable")
@export_tool_button("Add/Edit Patrol Path") var _edit_patrol_path: Callable = edit_patrol_path
@export var patrol_path: Path2D:
	set(new_value):
		patrol_path = new_value

@export_range(0, 5, 0.1, "or_greater", "suffix:s") var wait_time: float = 1.0
@export_range(20, 300, 5, "or_greater", "or_less", "suffix:m/s") var move_speed: float = 100.0

@export_category("Player Detection")
@export var player_instantly_detected_on_sight: bool = false
@export_range(0.1, 5, 0.1, "or_greater", "suffix:s") var time_to_detect_player: float = 1.0
@export_range(0.1, 5, 0.1, "or_greater", "or_less") var detection_area_scale: float = 1.0:
	set(new_value):
		detection_area_scale = new_value
		if detection_area:
			detection_area.scale = Vector2.ONE * detection_area_scale

@export_category("Debug")
@export var move_while_in_editor: bool = false
@export var show_debug_info: bool = false

var previous_patrol_point_idx: int = -1
var current_patrol_point_idx: int = 0
var last_seen_position: Vector2
var breadcrumbs: Array[Vector2] = []
var state: State = State.PATROLLING:
	set = _set_state

var _player: Node2D

@onready var detection_area: Area2D = %DetectionArea
@onready var player_awareness: TextureProgressBar = %PlayerAwareness
@onready var sight_ray_cast: RayCast2D = %SightRayCast
@onready var debug_info: Label = %DebugInfo

@onready
var character_animation_player_behavior: CharacterAnimationPlayerBehavior = %CharacterAnimationPlayerBehavior

@onready var guard_movement: MovimientoCustom = %GuardMovement
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
			warnings.push_back("sprite_frames is missing the following animation: %s" % required_animation)
	return warnings

func _enter_tree() -> void:
	remove_from_group("guard_enemy")

func _ready() -> void:
	if not Engine.is_editor_hint():
		if player_awareness:
			player_awareness.max_value = time_to_detect_player
			player_awareness.value = 0.0

	_set_sprite_frames(sprite_frames)

	if detection_area:
		detection_area.scale = Vector2.ONE * detection_area_scale

	if patrol_path:
		global_position = _patrol_point_position(0)

	guard_movement.destination_reached.connect(self._on_destination_reached)
	guard_movement.still_time_finished.connect(self._on_still_time_finished)
	guard_movement.path_blocked.connect(self._on_path_blocked)
	
	posicion_inicial = global_position
	
	if es_acosador:
		state = State.CHASING
		var jugadores = get_tree().get_nodes_in_group("player")
		if jugadores.size() > 0:
			_player = jugadores[0]
	elif solo_ronda_zona:
		state = State.WANDERING
		var primer_punto = _obtener_punto_aleatorio_en_zona()
		guard_movement.set_destination(primer_punto)


func _process(delta: float) -> void:
	_update_debug_info()

	if Engine.is_editor_hint() and not move_while_in_editor:
		return

	# --- NUEVO: RADAR DE PROXIMIDAD 360 ---
	if state != State.ALERTED and not es_acosador:
		var jugadores = get_tree().get_nodes_in_group("player")
		if jugadores.size() > 0:
			var jugador = jugadores[0]
			var distancia = global_position.distance_to(jugador.global_position)
			
			# Si te acercas por la espalda, te escucha y persigue
			if distancia <= radio_radar:
				_player = jugador
				state = State.CHASING if solo_ronda_zona else State.ALERTED
			
			# Si estabas siendo perseguido, huyes lejos del radar, y NO te está mirando, te pierde
			elif state == State.CHASING and distancia > radio_radar:
				if not detection_area.overlaps_body(jugador):
					last_seen_position = jugador.global_position
					_player = null
					guard_movement.stop_moving()
					state = State.INVESTIGATING
	# --------------------------------------

	_process_state()
	guard_movement.move()
	
	if state != State.ALERTED and state != State.CHASING:
		_update_player_awareness(delta)

	_update_animation()


func _process_state() -> void:
	match state:
		State.PATROLLING:
			if patrol_path:
				var target_position: Vector2 = _patrol_point_position(current_patrol_point_idx)
				guard_movement.set_destination(target_position)
			else:
				guard_movement.stop_moving()
		State.INVESTIGATING:
			guard_movement.set_destination(last_seen_position)
		State.RETURNING:
			if not breadcrumbs.is_empty():
				var target_position: Vector2 = breadcrumbs.back()
				guard_movement.set_destination(target_position)
			else:
				state = State.WANDERING if solo_ronda_zona else State.PATROLLING
				if state == State.WANDERING:
					var nuevo_punto = _obtener_punto_aleatorio_en_zona()
					guard_movement.set_destination(nuevo_punto)
		State.ALERTED:
			guard_movement.stop_moving()
		State.CHASING:
			if _player:
				guard_movement.set_destination(_player.global_position)
			else:
				guard_movement.stop_moving()
		State.WANDERING:
			pass


func _update_player_awareness(delta: float) -> void:
	var player_in_sight := _player and not _is_sight_to_point_blocked(_player.global_position)

	player_awareness.value = move_toward(
		player_awareness.value, player_awareness.max_value if player_in_sight else 0.0, delta
	)
	player_awareness.visible = player_awareness.ratio > 0.0
	player_awareness.modulate.a = clamp(player_awareness.ratio, 0.5, 1.0)

	if player_awareness.ratio >= 1.0:
		if solo_ronda_zona or es_acosador:
			# Si es acosador, NO te mata aún, solo empieza la persecución épica.
			state = State.CHASING
		else:
			state = State.ALERTED
			# Si es un guardia de ruta fija estándar, te mata enseguida al verte (como el original).
			if _player.has_method("defeat"):
				_player.defeat()
				
		player_detected.emit(_player)


func _update_animation() -> void:
	if state == State.ALERTED:
		return

	if velocity.is_zero_approx():
		animation_player.play(&"idle")
	else:
		animation_player.play(&"walk")


func _update_debug_info() -> void:
	debug_info.visible = show_debug_info
	if not debug_info.visible:
		return
	debug_info.text = ""
	debug_property("position")
	debug_value("state", State.keys()[state])
	debug_property("previous_patrol_point_idx")
	debug_property("current_patrol_point_idx")
	debug_value("time left", "%.2f" % guard_movement.still_time_left_in_seconds)
	debug_value("target point", guard_movement.destination)


func _on_destination_reached() -> void:
	match state:
		State.PATROLLING:
			guard_movement.wait_seconds(wait_time)
			_advance_target_patrol_point()
		State.INVESTIGATING:
			guard_movement.wait_seconds(wait_time)
		State.RETURNING:
			breadcrumbs.pop_back()
		State.WANDERING:
			guard_movement.wait_seconds(wait_time)


func _on_still_time_finished() -> void:
	match state:
		State.INVESTIGATING:
			state = State.RETURNING
		State.WANDERING:
			var nuevo_punto = _obtener_punto_aleatorio_en_zona()
			guard_movement.set_destination(nuevo_punto)


func _on_path_blocked() -> void:
	match state:
		State.PATROLLING:
			guard_movement.wait_seconds(wait_time)
			if previous_patrol_point_idx > -1:
				var new_patrol_point: int = previous_patrol_point_idx
				previous_patrol_point_idx = current_patrol_point_idx
				current_patrol_point_idx = new_patrol_point
		State.INVESTIGATING:
			state = State.RETURNING
		State.RETURNING:
			if not breadcrumbs.is_empty():
				breadcrumbs.pop_back()
		# SOLUCIÓN DE PARED: Si choca mientras deambula, busca otro punto de inmediato
		State.WANDERING:
			var nuevo_punto = _obtener_punto_aleatorio_en_zona()
			guard_movement.set_destination(nuevo_punto)


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
		State.INVESTIGATING:
			guard_movement.start_moving_now()
			breadcrumbs.push_back(global_position)
		State.CHASING:
			guard_movement.start_moving_now()
		State.WANDERING:
			guard_movement.start_moving_now()


func debug_property(property_name: String) -> void:
	debug_value(property_name, get(property_name))


func debug_value(value_name: String, value: Variant) -> void:
	debug_info.text += "%s: %s\n" % [value_name, value]


func _advance_target_patrol_point() -> void:
	if not patrol_path or not patrol_path.curve or _amount_of_patrol_points() < 2:
		return

	var new_patrol_point_idx: int

	if _is_patrol_path_closed():
		new_patrol_point_idx = (current_patrol_point_idx + 1) % (_amount_of_patrol_points() - 1)
	else:
		var at_last_point: bool = current_patrol_point_idx == (_amount_of_patrol_points() - 1)
		var at_first_point: bool = current_patrol_point_idx == 0
		var going_backwards_in_path: bool = previous_patrol_point_idx > current_patrol_point_idx
		if at_last_point:
			new_patrol_point_idx = current_patrol_point_idx - 1
		elif at_first_point:
			new_patrol_point_idx = current_patrol_point_idx + 1
		elif going_backwards_in_path:
			new_patrol_point_idx = current_patrol_point_idx - 1
		else:
			new_patrol_point_idx = current_patrol_point_idx + 1

	previous_patrol_point_idx = current_patrol_point_idx
	current_patrol_point_idx = new_patrol_point_idx


func _is_sight_to_point_blocked(point_position: Vector2) -> bool:
	sight_ray_cast.target_position = sight_ray_cast.to_local(point_position)
	sight_ray_cast.force_raycast_update()
	return sight_ray_cast.is_colliding()


func _patrol_point_position(point_idx: int) -> Vector2:
	var local_point_position: Vector2 = patrol_path.curve.get_point_position(point_idx)
	return patrol_path.to_global(local_point_position)


func _amount_of_patrol_points() -> int:
	return patrol_path.curve.point_count


func _is_patrol_path_closed() -> bool:
	if not patrol_path:
		return false
	var curve: Curve2D = patrol_path.curve
	if curve.point_count < 3:
		return false
	var first_point_position: Vector2 = curve.get_point_position(0)
	var last_point_position: Vector2 = curve.get_point_position(curve.point_count - 1)
	return first_point_position.is_equal_approx(last_point_position)


func _reset() -> void:
	previous_patrol_point_idx = -1
	current_patrol_point_idx = 0
	velocity = Vector2.ZERO
	if patrol_path:
		global_position = _patrol_point_position(0)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_EDITOR_PRE_SAVE:
			_reset()


static func _editor_interface() -> Object:
	return Engine.get_singleton("EditorInterface")


func edit_patrol_path() -> void:
	if not Engine.is_editor_hint():
		return
	var editor_interface := _editor_interface()
	if patrol_path:
		editor_interface.edit_node.call_deferred(patrol_path)
	else:
		var new_patrol_path: Path2D = Path2D.new()
		patrol_path = new_patrol_path
		get_parent().add_child(patrol_path)
		patrol_path.owner = owner
		patrol_path.global_position = global_position
		var patrol_path_curve: Curve2D = Curve2D.new()
		patrol_path.curve = patrol_path_curve
		patrol_path.name = "%s-PatrolPath" % name
		patrol_path_curve.add_point(Vector2.ZERO)
		patrol_path_curve.add_point(Vector2.RIGHT * 150.0)
		editor_interface.edit_node.call_deferred(patrol_path)


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


func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player = body
		if _is_sight_to_point_blocked(body.global_position):
			return
		if player_instantly_detected_on_sight:
			state = State.CHASING if (solo_ronda_zona or es_acosador) else State.ALERTED
			player_detected.emit(_player)
		else:
			state = State.DETECTING


func _on_instant_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		state = State.CHASING if (solo_ronda_zona or es_acosador) else State.ALERTED
		
		# --- NUEVO: El guardia ejecuta la derrota por su cuenta al tocarte ---
		if body.has_method("defeat"):
			body.defeat()
		# --------------------------------------------------------------------
		
		player_detected.emit(body)


func _obtener_punto_aleatorio_en_zona() -> Vector2:
	var angulo_al_azar: float = randf_range(0, 2 * PI)
	var distancia_al_azar: float = randf_range(50, radio_patrulla)
	var despliegue = Vector2(cos(angulo_al_azar), sin(angulo_al_azar)) * distancia_al_azar
	return posicion_inicial + despliegue


func _draw() -> void:
	if Engine.is_editor_hint() or show_debug_info:
		# Seguro profesional: Extraemos los valores de forma segura. 
		# Si por alguna razón Godot los lee como "Nil" (vacíos), forzamos un valor temporal.
		var r_pat: float = float(radio_patrulla) if typeof(radio_patrulla) != TYPE_NIL else 250.0
		var r_rad: float = float(radio_radar) if typeof(radio_radar) != TYPE_NIL else 100.0
		
		# Círculo Celeste: Zona por la que puede caminar
		var color_circulo = Color(0.2, 0.6, 1.0, 0.25)
		draw_arc(Vector2.ZERO, r_pat, 0, 2 * PI, 64, color_circulo, 2.0)
		
		# Círculo Rojo: NUEVO RADAR de proximidad
		var color_radar = Color(1.0, 0.2, 0.2, 0.25)
		draw_arc(Vector2.ZERO, r_rad, 0, 2 * PI, 64, color_radar, 2.0)


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == _player:
		# Para que te pierda, debes salir del cono de luz Y ADEMÁS estar fuera del círculo rojo
		var distancia = global_position.distance_to(body.global_position)
		if distancia > radio_radar:
			last_seen_position = body.global_position 
			_player = null
			if state == State.DETECTING or state == State.CHASING:
				guard_movement.stop_moving()
				state = State.INVESTIGATING
				
