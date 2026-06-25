# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name Player
extends CharacterBody2D

signal mode_changed(mode: Mode)

## The possible player states.
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

# ------------------------------------------------------------
# Salud del jugador
# ------------------------------------------------------------
@export var max_hp: int = 100
var hp: int

# ------------------------------------------------------------
# Ataque cuerpo a cuerpo
# ------------------------------------------------------------
@export var attack_damage: int = 1
@export var attack_cooldown: float = 0.5
@export var attack_range: float = 80.0
var can_attack: bool = true
# ------------------------------------------------------------

@export_group("Sounds")
@export var walk_sound_stream: AudioStream = preload("uid://cx6jv2cflrmqu"):
	set = _set_walk_sound_stream

var _initial_speeds: CharacterSpeeds

@onready var input_walk_behavior: InputWalkBehavior = %InputWalkBehavior
@onready var player_interaction: PlayerInteraction = %PlayerInteraction
@onready var player_repel: Node2D = %PlayerRepel
@onready var player_hook: PlayerHook = %PlayerHook
@onready var player_sprite: AnimatedSprite2D = %PlayerSprite
@onready var _walk_sound: AudioStreamPlayer2D = %WalkSound

# Referencias a la barra de vida y la etiqueta de texto
@onready var health_bar: ProgressBar = $ProgressBar
@onready var health_label: Label = $ProgressBar/Label


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

	var animations: Dictionary[StringName, int] = REQUIRED_ANIMATION_FRAMES.merged(OPTIONAL_ANIMATION_FRAMES)
	for animation: StringName in animations:
		if not sprite_frames.has_animation(animation):
			continue
		var count := sprite_frames.get_frame_count(animation)
		var expected_count := animations[animation]
		if count != expected_count:
			warnings.append("sprite_frames animation %s has %d frames, but should have %d" % [animation, count, expected_count])
	return warnings


func _ready() -> void:
	add_to_group("player")
	add_to_group("target_player")

	collision_layer = 1
	collision_mask = 1 | 2

	_set_speeds(speeds)
	_set_mode(mode)
	_set_sprite_frames(sprite_frames)
	GameState.abilities_changed.connect(_on_abilities_changed)

	hp = max_hp

	# Inicializar la barra de vida
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = hp
	# Inicializar la etiqueta de vida
	if health_label:
		health_label.text = "HP|" + str(hp) + "/" + str(max_hp)


func _set_speeds(new_speeds: CharacterSpeeds) -> void:
	speeds = new_speeds
	_initial_speeds = new_speeds.duplicate()
	if not is_node_ready():
		return
	input_walk_behavior.speeds = speeds


func teleport_to(tele_position: Vector2, smooth_camera: bool = false, look_side: Enums.LookAtSide = Enums.LookAtSide.UNSPECIFIED) -> void:
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


## Recibe daño de enemigos. Si la vida llega a 0, se llama a defeat().
func take_damage(amount: int) -> void:
	if mode == Mode.DEFEATED:
		return

	hp -= amount
	hp = clamp(hp, 0, max_hp)
	print("JUGADOR - HP: ", hp, "/", max_hp)

	# Actualizar la barra de vida
	if health_bar:
		health_bar.value = hp
	# Actualizar la etiqueta de vida
	if health_label:
		health_label.text = "HP|" + str(hp) + "/" + str(max_hp)

	if hp <= 0:
		defeat()


## Restaura puntos de vida (por botiquines o habilidades).
## No puede superar max_hp.
func heal(amount: int) -> void:
	if mode == Mode.DEFEATED:
		return
	hp += amount
	hp = clamp(hp, 0, max_hp)
	print("JUGADOR - Cura: ", amount, " HP: ", hp, "/", max_hp)
	if health_bar:
		health_bar.value = hp
	if health_label:
		health_label.text = "HP|" + str(hp) + "/" + str(max_hp)


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
		SceneSwitcher.change_to_file_with_transition(challenge_start_scene, ^"", Transition.Effect.FADE, Transition.Effect.FADE)


func _on_player_hook_aiming_changed(is_aiming: bool) -> void:
	input_walk_behavior.speeds.walk_speed = aiming_speed if is_aiming else _initial_speeds.walk_speed
	input_walk_behavior.speeds.run_speed = aiming_speed if is_aiming else _initial_speeds.run_speed


# ------------------------------------------------------------
# Ataque cuerpo a cuerpo (integrado)
# ------------------------------------------------------------
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("attack") and can_attack and mode != Mode.DEFEATED:
		_melee_attack()

func _melee_attack() -> void:
	can_attack = false
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.has_method("take_damage"):
			var dist: float = global_position.distance_to(enemy.global_position)
			if dist <= attack_range:
				enemy.take_damage(attack_damage)
				print("Golpe a ", enemy.name)
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
