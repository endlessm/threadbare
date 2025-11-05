@tool
class_name SecurityCamera
extends Node2D

## --- Señales ---
signal player_detected(player: Node2D)

## --- Estados de la cámara ---
enum CameraState { IDLE, SUSPICIOUS, ALERT }

## --- Apariencia ---
@export var normal_color: Color = Color(0.0, 0.8, 1.0, 0.3)
@export var suspicious_color: Color = Color(1.0, 0.8, 0.0, 0.5)
@export var alert_color: Color = Color(1.0, 0.0, 0.0, 0.7)

## --- Rotación ---
@export_range(10, 120, 5) var rotation_speed: float = 30.0
@export_range(30, 180, 5) var max_rotation_angle: float = 90.0
@export_range(0, 3, 0.1) var pause_time: float = 1.0

## --- Detección ---
@export_range(20, 120, 5) var vision_cone_angle: float = 45.0
@export_range(100, 1000, 50) var detection_range: float = 400.0
@export_range(0.5, 5, 0.1) var time_to_detect: float = 2.0
@export var see_through_walls: bool = false

## --- Sonidos ---
@export var alert_sound: AudioStream
@export var suspicious_sound: AudioStream

## --- Variables internas ---
var state: CameraState = CameraState.IDLE
var current_rotation_direction: int = 1
var initial_rotation: float = 0.0
var pause_timer: float = 0.0
var detection_progress: float = 0.0
var player_in_range: Node2D = null

## --- Nodos ---
@onready var vision_area: Area2D = $VisionArea
@onready var light: PointLight2D = $Light
@onready var detection_ray: RayCast2D = $DetectionRay
@onready var alert_audio: AudioStreamPlayer2D = $AlertAudio
@onready var suspicious_audio: AudioStreamPlayer2D = $SuspiciousAudio


func _ready() -> void:
	initial_rotation = rotation_degrees
	
	if not Engine.is_editor_hint():
		if vision_area:
			vision_area.body_entered.connect(_on_vision_area_body_entered)
			vision_area.body_exited.connect(_on_vision_area_body_exited)

		if alert_audio and alert_sound:
			alert_audio.stream = alert_sound
		if suspicious_audio and suspicious_sound:
			suspicious_audio.stream = suspicious_sound


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	_update_rotation(delta)
	_update_detection(delta)
	_update_visuals()


## --- ROTACIÓN AUTOMÁTICA ---
func _update_rotation(delta: float) -> void:
	if pause_timer > 0:
		pause_timer -= delta
		return
	
	rotation_degrees += rotation_speed * delta * current_rotation_direction
	
	var angle_from_initial = rotation_degrees - initial_rotation
	if abs(angle_from_initial) >= max_rotation_angle:
		rotation_degrees = initial_rotation + (max_rotation_angle * current_rotation_direction)
		current_rotation_direction *= -1
		pause_timer = pause_time


## --- DETECCIÓN DEL JUGADOR ---
func _update_detection(delta: float) -> void:
	var player_visible = _is_player_in_vision()
	
	if player_visible:
		detection_progress += delta / time_to_detect
		if detection_progress >= 1.0:
			detection_progress = 1.0
			if state != CameraState.ALERT:
				_trigger_alert()
		elif state == CameraState.IDLE:
			state = CameraState.SUSPICIOUS
			if suspicious_audio and not suspicious_audio.playing:
				suspicious_audio.play()
	else:
		if detection_progress > 0:
			detection_progress -= delta / (time_to_detect * 0.5)
			detection_progress = max(0.0, detection_progress)
		
		if detection_progress <= 0 and state == CameraState.SUSPICIOUS:
			state = CameraState.IDLE


## --- VISIÓN ---
func _is_player_in_vision() -> bool:
	if not player_in_range:
		return false
	
	var player_pos = player_in_range.global_position
	var to_player = (player_pos - global_position)
	var distance = to_player.length()
	
	if distance > detection_range:
		return false
	
	var angle_to_player = rad_to_deg(to_player.angle() - global_rotation)
	angle_to_player = wrapf(angle_to_player, -180, 180)
	
	if abs(angle_to_player) > vision_cone_angle / 2.0:
		return false
	
	if not see_through_walls and detection_ray:
		detection_ray.target_position = to_local(player_pos)
		detection_ray.force_raycast_update()
		if detection_ray.is_colliding():
			var collider = detection_ray.get_collider()
			if collider != player_in_range:
				return false
	
	return true


## --- EFECTOS VISUALES ---
func _update_visuals() -> void:
	if not light:
		return
	
	match state:
		CameraState.IDLE:
			light.color = Color(0.0, 1.0, 0.5)
			light.energy = 0.5
		CameraState.SUSPICIOUS:
			light.color = Color.YELLOW.lerp(Color.RED, detection_progress)
			light.energy = 0.5 + (detection_progress * 0.5)
		CameraState.ALERT:
			light.color = Color.RED
			light.energy = 1.5


## --- ALERTA ---
func _trigger_alert() -> void:
	state = CameraState.ALERT
	print("🚨 ¡CÁMARA '", name, "' DETECTÓ AL JUGADOR!")
	if alert_audio and not alert_audio.playing:
		alert_audio.play()
	if player_in_range:
		player_detected.emit(player_in_range)
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(self):
		state = CameraState.IDLE
		detection_progress = 0.0


## --- DETECCIÓN DEL ÁREA ---
func _on_vision_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = body
		print("👁️ Jugador entró en rango de cámara '", name, "'")


func _on_vision_area_body_exited(body: Node2D) -> void:
	if body == player_in_range:
		player_in_range = null
		print("🌑 Jugador salió del rango de cámara '", name, "'")
		
