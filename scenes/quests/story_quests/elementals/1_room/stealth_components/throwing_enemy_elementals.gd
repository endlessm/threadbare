# Archivo: ThrowingEnemyelementals.gd

# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name ThrowingEnemyelementals
extends CharacterBody2D

enum State { IDLE, WALKING, ATTACKING, DEFEATED }

const REQUIRED_ANIMATIONS: Array[StringName] = [
	&"idle", &"walk", &"attack", &"attack anticipation", &"defeated"
]

const DEFAULT_SPRITE_FRAME: SpriteFrames = preload("uid://deosvk5k4su5f")
const WALK_TARGET_SKIP_ANGLE: float = PI / 4.
const WALK_TARGET_SKIP_RANGE: float = 0.25

@export var projectile_scene: PackedScene = preload("res://scenes/quests/story_quests/elementals/1_room/stealth_components/projectile_elementals.tscn")
@export_range(0.1, 10., 0.1, "or_greater", "suffix:s") var throwing_period: float = 5.0
@export var odd_shoot: bool = false
@export var autostart: bool = false

@export_group("Visuals")
@export var sprite_frames: SpriteFrames = DEFAULT_SPRITE_FRAME:
	set = _set_sprite_frames

@export_group("Sounds")
@export var idle_sound_stream: AudioStream:
	set = _set_idle_sound_stream
@export var attack_sound_stream: AudioStream:
	set = _set_attack_sound_stream

@export_group("Projectile", "projectile")
@export_range(0., 100., 1., "or_greater", "suffix:m") var distance: float = 20.0
@export_range(10., 100., 5., "or_greater", "or_less", "suffix:m/s")
var projectile_speed: float = 30.0
@export_range(0., 10., 0.1, "or_greater", "suffix:s") var projectile_duration: float = 5.0
@export var projectile_follows_player: bool = false
@export var projectile_sprite_frames: SpriteFrames = preload("uid://b00dcfe4dtvkh")
@export var projectile_hit_sound_stream: AudioStream
@export var projectile_small_fx_scene: PackedScene
@export var projectile_big_fx_scene: PackedScene
@export var projectile_trail_fx_scene: PackedScene

@export_group("Walking", "walking")
@export_range(0., 10., 0.1, "or_greater", "suffix:s") var walking_time: float = 0.0:
	set(value):
		walking_time = value
		queue_redraw()
@export_range(0., 500., 1., "or_greater", "suffix:m") var walking_range: float = 300.0:
	set(value):
		walking_range = value
		queue_redraw()
@export_range(20, 300, 5, "or_greater", "or_less", "suffix:m/s") var walking_speed: float = 50.0

# --- SISTEMA DE VIDA DEL ENEMIGO ---
@export var max_health: int = 3 
var health: int
var tween: Tween

# --- FUNCIÓN CORREGIDA: USA ANIMATEDSPRITE2D ---
func take_damage(amount: int):
	health -= amount
	print("[ThrowingEnemy] Recibí daño. Vida restante:", health)
	
	# Ejecutamos el parpadeo en el sprite
	flash_red()
	
	# NOTA: Quitamos 'animation_player.play("got hit")' para evitar errores
	# si esa animación no existe en el AnimationPlayer.

	if health <= 0:
		die()

func flash_red():
	if tween:
		tween.kill()
	
	tween = create_tween()
	# Usamos 'animated_sprite_2d' que es la referencia correcta en este script
	tween.tween_property(animated_sprite_2d, "modulate", Color.RED, 0.0)
	tween.tween_interval(0.1)
	tween.tween_property(animated_sprite_2d, "modulate", Color.WHITE, 0.0)

func die():
	if _is_defeated:
		return
	print("[ThrowingEnemy] He muerto 💀")
	_is_defeated = true

	timer.stop()
	_is_attacking = false

	# Usamos la animación de muerte del Sprite directamente si existe,
	# o mantenemos el AnimationPlayer si tienes una animación compleja ahí.
	# Por seguridad, intentamos reproducir la animación en ambos o priorizamos el AnimationPlayer
	# si tu lógica de "defeat" (desaparecer) depende de él.
	animation_player.play("defeated") 

	hit_box.monitoring = false
	hit_box.monitorable = false
	if $CollisionShape2D:
		$CollisionShape2D.disabled = true

	if not animation_player.animation_finished.is_connected(_on_death_animation_finished):
		animation_player.animation_finished.connect(_on_death_animation_finished)

func _on_death_animation_finished(anim_name: String) -> void:
	if anim_name == "defeated":
		queue_free()
# --- FIN CAMBIOS ELEMENTAL ---

@export var allowed_labels: Array[String] = ["???"]
var color_per_label: Dictionary[String, Color]

var _initial_position: Vector2
var _target_position: Vector2
var _is_attacking: bool
var _is_defeated: bool
var _has_started: bool = false

@onready var timer: Timer = %Timer
@onready var projectile_marker: Marker2D = %ProjectileMarker
@onready var hit_box: Area2D = %HitBox
@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var _idle_sound: AudioStreamPlayer2D = %IdleSound
@onready var _attack_sound: AudioStreamPlayer2D = %AttackSound


func _set_sprite_frames(new_sprite_frames: SpriteFrames) -> void:
	sprite_frames = new_sprite_frames
	if not is_node_ready():
		return
	if new_sprite_frames == null:
		new_sprite_frames = DEFAULT_SPRITE_FRAME
	animated_sprite_2d.sprite_frames = new_sprite_frames
	update_configuration_warnings()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: Array = []
	for animation in REQUIRED_ANIMATIONS:
		if not sprite_frames.has_animation(animation):
			warnings.append("sprite_frames is missing the following animation: %s" % animation)
	return warnings


func _ready() -> void:
	health = max_health
	_initial_position = position
	_set_sprite_frames(sprite_frames)
	
	if not hit_box.body_entered.is_connected(_on_hit_box_body_entered):
		hit_box.body_entered.connect(_on_hit_box_body_entered)
	
	if Engine.is_editor_hint():
		return
	var player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player):
		var direction: Vector2 = projectile_marker.global_position.direction_to(
			player.global_position
		)
		scale.x = 1 if direction.x < 0 else -1
	if autostart:
		start()


func _draw() -> void:
	if walking_time == 0 or walking_range == 0:
		return
	if Engine.is_editor_hint() or get_tree().is_debugging_collisions_hint():
		draw_circle(_initial_position - position, walking_range, Color(0.0, 1.0, 1.0, 0.3))
		draw_circle(
			_initial_position - position,
			walking_range * WALK_TARGET_SKIP_RANGE,
			Color(0.0, 0.0, 0.0, 0.3)
		)
		if get_tree().is_debugging_collisions_hint():
			draw_circle(_target_position - position, 10., Color(1.0, 0.0, 0.0, 0.7))


func _get_state() -> State:
	if _is_defeated:
		return State.DEFEATED
	if _is_attacking:
		return State.ATTACKING
	if is_zero_approx(walking_time) or is_zero_approx(walking_range):
		return State.IDLE
	if timer.is_stopped() or timer.paused:
		return State.IDLE
	var walk_start_time: float
	var walk_end_time: float
	if walking_time > timer.wait_time:
		walk_start_time = 0.0
		walk_end_time = timer.wait_time
	else:
		walk_start_time = (timer.wait_time - walking_time) / 2
		walk_end_time = walk_start_time + walking_time
	if walk_end_time < timer.time_left or timer.time_left < walk_start_time:
		return State.IDLE
	return State.WALKING


func _get_velocity() -> Vector2:
	var delta: Vector2 = _target_position - position
	if delta.is_zero_approx():
		return Vector2.ZERO
	return position.direction_to(_target_position) * min(delta.length(), walking_speed)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var state: State = _get_state()
	match state:
		State.ATTACKING, State.DEFEATED:
			return
		State.IDLE:
			if animated_sprite_2d.animation not in [&"attack anticipation", &"attack"]:
				animation_player.play("idle")
			return
		State.WALKING:
			velocity = _get_velocity()
			move_and_slide()
			if get_tree().is_debugging_collisions_hint():
				queue_redraw()
			if not velocity.is_zero_approx():
				animated_sprite_2d.play(&"walk")


func _set_target_position() -> void:
	var current_angle := _initial_position.angle_to_point(position)
	var start_angle := current_angle + WALK_TARGET_SKIP_ANGLE / 2.
	var end_angle := 2 * PI - current_angle - WALK_TARGET_SKIP_ANGLE / 2.
	_target_position = (
		_initial_position
		+ (
			Vector2.LEFT.rotated(randf_range(start_angle, end_angle))
			* walking_range
			* randf_range(WALK_TARGET_SKIP_RANGE, 1.0)
		)
	)


func _on_timeout() -> void:
	print("[ThrowingEnemyelementals] _on_timeout() — timer fired for ", self.name)
	var player = get_tree().get_first_node_in_group("player")
	
	if not is_instance_valid(player):
		print("[ThrowingEnemyelementals] no valid player found")
		return
	_is_attacking = true
	animation_player.play(&"attack")
	animation_player.queue(&"idle")


func shoot_projectile() -> void:
	print("[ThrowingEnemyelementals] shoot_projectile() called")
	var player = get_tree().get_first_node_in_group("player")

	if not is_instance_valid(player):
		print("[ThrowingEnemyelementals] shoot_projectile: player not valid")
		_is_attacking = false
		return
	if not allowed_labels:
		_is_attacking = false
		print("[ThrowingEnemyelementals] no allowed_labels, abort")
		return
	
	var projectile = projectile_scene.instantiate()
	
	if projectile == null:
		print("[ThrowingEnemyelementals] projectile_scene.instantiate() returned null")
		return
	projectile.direction = projectile_marker.global_position.direction_to(player.global_position)
	scale.x = 1 if projectile.direction.x < 0 else -1
	
	projectile.label = allowed_labels.pick_random()
	
	if projectile.label in color_per_label:
		projectile.color = color_per_label[projectile.label]
	projectile.global_position = projectile_marker.global_position + projectile.direction * distance
	if projectile_follows_player:
		projectile.node_to_follow = player
	projectile.sprite_frames = projectile_sprite_frames
	projectile.hit_sound_stream = projectile_hit_sound_stream
	projectile.small_fx_scene = projectile_small_fx_scene
	projectile.big_fx_scene = projectile_big_fx_scene
	projectile.trail_fx_scene = projectile_trail_fx_scene
	projectile.speed = projectile_speed
	projectile.duration = projectile_duration
	
	projectile.add_to_group("enemy_projectile")
	projectile.add_to_group("projectiles")
	
	get_tree().current_scene.add_child(projectile)
	print("[ThrowingEnemyelementals] projectile spawned at ", projectile.global_position, " direction ", projectile.direction)
	_set_target_position()
	_is_attacking = false


func start() -> void:
	if _has_started:
		return
	_has_started = true
	if not is_node_ready():
		await ready
	print("[ThrowingEnemyelementals] start() called on ", self.name)
	timer.wait_time = throwing_period
	if not timer.timeout.is_connected(_on_timeout):
		timer.timeout.connect(_on_timeout)

	if odd_shoot:
		await get_tree().create_timer(throwing_period / 2).timeout
	timer.start()
	_initial_position = position
	_set_target_position()


func remove() -> void:
	timer.stop()
	_is_defeated = true
	animation_player.play(&"defeated")
	await animation_player.animation_finished
	queue_free()


func _set_idle_sound_stream(new_value: AudioStream) -> void:
	idle_sound_stream = new_value
	if not is_node_ready():
		await ready
	_idle_sound.stream = new_value


func _set_attack_sound_stream(new_value: AudioStream) -> void:
	attack_sound_stream = new_value
	if not is_node_ready():
		await ready
	_attack_sound.stream = new_value


func _on_hit_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("bullet"):
		call_deferred("take_damage", 1)
		body.queue_free()
