# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name Player
extends CharacterBody2D

signal mode_changed(mode: Mode)
signal health_changed(current_health: int, max_health: int)

enum Mode {
	USER_CONTROLLED,
	SYSTEM_CONTROLLED,
	DEFEATED,
}

const REQUIRED_ANIMATION_FRAMES: Dictionary[StringName, int] = {
	&"idle": 10,
	&"walk": 6,
	&"attack_01": 4,
	&"attack_02": 4,
	&"defeated": 11,
}

const OPTIONAL_ANIMATION_FRAMES: Dictionary[StringName, int] = {
	&"run": 6,
}

const DEFAULT_SPRITE_FRAME: SpriteFrames = preload("uid://vwf8e1v8brdp")

@export var player_name: String = "Player Name"

@export var mode: Mode = Mode.USER_CONTROLLED:
	set = _set_mode

@export var speeds: CharacterSpeeds:
	set = _set_speeds

@export_range(10, 100000, 10) var aiming_speed: float = 100.0

@export var sprite_frames: SpriteFrames = DEFAULT_SPRITE_FRAME:
	set = _set_sprite_frames

@export_group("Sounds")
@export var walk_sound_stream: AudioStream = preload("uid://cx6jv2cflrmqu"):
	set = _set_walk_sound_stream

@export_group("Sword Attack")
@export var sword_damage: int = 25
@export var sword_active_frame_start: int = 1
@export var sword_active_frame_end: int = 2
@export var sword_attack_duration: float = 0.45

@export_group("Health")
@export var max_health: int = 100

var current_health: int
var _initial_speeds: CharacterSpeeds

@onready var input_walk_behavior: InputWalkBehavior = %InputWalkBehavior
@onready var player_interaction: PlayerInteraction = %PlayerInteraction
@onready var player_repel: Node2D = %PlayerRepel
@onready var player_hook: PlayerHook = %PlayerHook
@onready var player_sprite: AnimatedSprite2D = %PlayerSprite
@onready var _walk_sound: AudioStreamPlayer2D = %WalkSound

@onready var sword_hitbox: Area2D = get_node_or_null("SwordHitbox")
@onready var sword_collision: CollisionShape2D = get_node_or_null("SwordHitbox/CollisionShape2D")

var is_attacking: bool = false
var sword_can_damage: bool = true
var last_attack_direction: Vector2 = Vector2.RIGHT


func _set_mode(new_mode: Mode) -> void:
	var previous_mode: Mode = mode
	mode = new_mode

	if not is_node_ready():
		return

	match mode:
		Mode.USER_CONTROLLED:
			_toggle_player_behavior(input_walk_behavior, true)
			_toggle_player_behavior(player_interaction, true)
			_toggle_abilities()

		Mode.SYSTEM_CONTROLLED:
			_toggle_player_behavior(input_walk_behavior, false)
			_toggle_player_behavior(player_interaction, true)
			_toggle_abilities()

		Mode.DEFEATED:
			_toggle_player_behavior(input_walk_behavior, false)
			_toggle_player_behavior(player_interaction, false)
			_toggle_player_behavior(player_repel, false)
			_toggle_player_behavior(player_hook, false)

	if mode != previous_mode:
		mode_changed.emit(mode)


func _set_sprite_frames(new_sprite_frames: SpriteFrames) -> void:
	sprite_frames = new_sprite_frames

	if not is_node_ready():
		return

	if new_sprite_frames == null:
		new_sprite_frames = DEFAULT_SPRITE_FRAME

	player_sprite.sprite_frames = new_sprite_frames
	update_configuration_warnings()


func _toggle_player_behavior(behavior_node: Node2D, is_active: bool) -> void:
	behavior_node.visible = is_active
	behavior_node.process_mode = (
		ProcessMode.PROCESS_MODE_INHERIT if is_active else ProcessMode.PROCESS_MODE_DISABLED
	)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray

	for animation: StringName in REQUIRED_ANIMATION_FRAMES:
		if not sprite_frames.has_animation(animation):
			warnings.append("sprite_frames is missing the following animation: %s" % animation)

	var animations: Dictionary[StringName, int] = REQUIRED_ANIMATION_FRAMES.merged(
		OPTIONAL_ANIMATION_FRAMES
	)

	for animation: StringName in animations:
		if not sprite_frames.has_animation(animation):
			continue

		var count := sprite_frames.get_frame_count(animation)
		var expected_count := animations[animation]

		if count != expected_count:
			warnings.append(
				(
					"sprite_frames animation %s has %d frames, but should have %d"
					% [animation, count, expected_count]
				)
			)

	return warnings


func _ready() -> void:
	_set_speeds(speeds)
	_set_mode(mode)
	_set_sprite_frames(sprite_frames)

	GameState.abilities_changed.connect(_on_abilities_changed)

	current_health = max_health
	health_changed.emit(current_health, max_health)

	if sword_hitbox == null:
		push_error("ERROR: Falta SwordHitbox como hijo directo de Player.")
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

	if event.is_action_pressed("attack") and not event.is_echo():
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


func _set_speeds(new_speeds: CharacterSpeeds) -> void:
	speeds = new_speeds

	if new_speeds != null:
		_initial_speeds = new_speeds.duplicate()

	if not is_node_ready():
		return

	input_walk_behavior.speeds = speeds


func teleport_to(
	tele_position: Vector2,
	smooth_camera: bool = false,
	look_side: Enums.LookAtSide = Enums.LookAtSide.UNSPECIFIED
) -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()

	if is_instance_valid(camera):
		var smoothing_was_enabled: bool = camera.position_smoothing_enabled
		camera.position_smoothing_enabled = smooth_camera
		global_position = tele_position
		%PlayerSprite.look_at_side(look_side)
		await get_tree().process_frame
		camera.position_smoothing_enabled = smoothing_was_enabled
	else:
		global_position = tele_position


func _set_walk_sound_stream(new_value: AudioStream) -> void:
	walk_sound_stream = new_value

	if not is_node_ready():
		await ready

	_walk_sound.stream = walk_sound_stream


func defeat(falling: bool = false) -> void:
	if mode == Player.Mode.DEFEATED:
		return

	mode = Player.Mode.DEFEATED
	velocity = Vector2.ZERO

	GameState.decrement_lives()

	if falling:
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2.ZERO, 2.0)

	await get_tree().create_timer(2.0).timeout

	if GameState.current_lives > 0:
		SceneSwitcher.reload_with_transition(Transition.Effect.FADE, Transition.Effect.FADE)
	else:
		_handle_game_over()


func take_control(_controlled_by: Node) -> void:
	mode = Mode.SYSTEM_CONTROLLED


func return_control(_controlled_by: Node) -> void:
	mode = Mode.USER_CONTROLLED


func _toggle_abilities() -> void:
	var can_repel := GameState.has_ability(Enums.PlayerAbilities.ABILITY_A)
	var can_grapple := GameState.has_ability(Enums.PlayerAbilities.ABILITY_B)

	_toggle_player_behavior(player_repel, can_repel)
	_toggle_player_behavior(player_hook, can_grapple)

	if can_grapple:
		var has_longer_hook := GameState.has_ability(Enums.PlayerAbilities.ABILITY_B_MODIFIER_1)
		player_hook.string_throw_length = 400.0 if has_longer_hook else 200.0
		player_hook.string_max_length = 450.0 if has_longer_hook else 250.0


func _on_abilities_changed() -> void:
	if mode != Mode.DEFEATED:
		_toggle_abilities()


func _handle_game_over() -> void:
	GameState.reset_lives()

	var challenge_start_scene: String = GameState.get_challenge_start_scene()

	if challenge_start_scene.is_empty():
		GameState.set_current_spawn_point(^"")
		SceneSwitcher.reload_with_transition(Transition.Effect.FADE, Transition.Effect.FADE)
	else:
		SceneSwitcher.change_to_file_with_transition(
			challenge_start_scene,
			^"",
			Transition.Effect.FADE,
			Transition.Effect.FADE
		)


func _on_player_hook_aiming_changed(is_aiming: bool) -> void:
	input_walk_behavior.speeds.walk_speed = (
		aiming_speed if is_aiming else _initial_speeds.walk_speed
	)

	input_walk_behavior.speeds.run_speed = (
		aiming_speed if is_aiming else _initial_speeds.run_speed
	)
