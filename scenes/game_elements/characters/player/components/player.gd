# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name Player
extends CharacterBody2D

signal mode_changed(mode: Mode)

# --- VARIABLES DE DISPARO ---
var puede_disparar: bool = false
var balas_restantes: int = 3
var ultima_direccion: Vector2 = Vector2.RIGHT
var escena_proyectil = preload("res://scenes/quests/story_quests/perdidos_en_el_desie/2_combat/proyectil.tscn") 

enum Mode { USER_CONTROLLED, SYSTEM_CONTROLLED, DEFEATED }

const REQUIRED_ANIMATION_FRAMES: Dictionary[StringName, int] = {
	&"idle": 10, &"walk": 6, &"attack_01": 4, &"attack_02": 4, &"defeated": 11,
}

const OPTIONAL_ANIMATION_FRAMES: Dictionary[StringName, int] = { &"run": 6 }
const DEFAULT_SPRITE_FRAME: SpriteFrames = preload("uid://vwf8e1v8brdp")

@export var player_name: String = "Player Name"
@export var mode: Mode = Mode.USER_CONTROLLED: set = _set_mode
@export var speeds: CharacterSpeeds: set = _set_speeds
@export_range(10, 100000, 10) var aiming_speed: float = 100.0
@export var sprite_frames: SpriteFrames = DEFAULT_SPRITE_FRAME: set = _set_sprite_frames
@export var walk_sound_stream: AudioStream = preload("uid://cx6jv2cflrmqu"): set = _set_walk_sound_stream

var _initial_speeds: CharacterSpeeds

@onready var input_walk_behavior: InputWalkBehavior = %InputWalkBehavior
@onready var player_interaction: PlayerInteraction = %PlayerInteraction
@onready var player_repel: Node2D = %PlayerRepel
@onready var player_hook: PlayerHook = %PlayerHook
@onready var player_sprite: AnimatedSprite2D = %PlayerSprite
@onready var _walk_sound: AudioStreamPlayer2D = %WalkSound

# --- CAPTURAR DIRECCIÓN DEL JUGADOR ---
func _physics_process(delta: float) -> void:
	var direccion = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direccion.length() > 0:
		ultima_direccion = direccion.normalized()

# --- LÓGICA DE DISPARO ---
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		intentar_disparar()

func intentar_disparar() -> void:
	if puede_disparar and balas_restantes > 0 and mode == Mode.USER_CONTROLLED:
		balas_restantes -= 1
		var b = escena_proyectil.instantiate()
		get_tree().current_scene.add_child(b)
		b.iniciar(global_position, ultima_direccion)

# --- CÓDIGO ORIGINAL Y SETTERS ---
func _set_mode(new_mode: Mode) -> void:
	var previous_mode: Mode = mode
	mode = new_mode
	if not is_node_ready(): return
	
	match mode:
		Mode.USER_CONTROLLED:
			_toggle_player_behavior(input_walk_behavior, true)
			_toggle_player_behavior(player_interaction, true)
			_toggle_abilities()
		Mode.SYSTEM_CONTROLLED:
			_toggle_player_behavior(input_walk_behavior, false)
			_toggle_player_behavior(player_interaction, true)
			_toggle_abilities()
			velocity = Vector2.ZERO 
		Mode.DEFEATED:
			_toggle_player_behavior(input_walk_behavior, false)
			_toggle_player_behavior(player_interaction, false)
			_toggle_player_behavior(player_repel, false)
			_toggle_player_behavior(player_hook, false)
			velocity = Vector2.ZERO
			
	if mode != previous_mode: mode_changed.emit(mode)

func _set_sprite_frames(new_sprite_frames: SpriteFrames) -> void:
	sprite_frames = new_sprite_frames
	if not is_node_ready(): return
	if new_sprite_frames == null: new_sprite_frames = DEFAULT_SPRITE_FRAME
	player_sprite.sprite_frames = new_sprite_frames

func _set_walk_sound_stream(new_value: AudioStream) -> void:
	walk_sound_stream = new_value
	if not is_node_ready(): await ready
	_walk_sound.stream = walk_sound_stream

func _toggle_player_behavior(behavior_node: Node2D, is_active: bool) -> void:
	behavior_node.visible = is_active
	behavior_node.process_mode = ProcessMode.PROCESS_MODE_INHERIT if is_active else ProcessMode.PROCESS_MODE_DISABLED

func _ready() -> void:
	_set_speeds(speeds)
	_set_mode(mode)
	_set_sprite_frames(sprite_frames)
	GameState.abilities_changed.connect(_on_abilities_changed)

func _set_speeds(new_speeds: CharacterSpeeds) -> void:
	speeds = new_speeds
	_initial_speeds = new_speeds.duplicate()
	if is_node_ready(): input_walk_behavior.speeds = speeds

func defeat(falling: bool = false) -> void:
	if mode == Player.Mode.DEFEATED: return
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

func _toggle_abilities() -> void:
	var can_repel := GameState.has_ability(Enums.PlayerAbilities.ABILITY_A)
	var can_grapple := GameState.has_ability(Enums.PlayerAbilities.ABILITY_B)
	_toggle_player_behavior(player_repel, can_repel)
	_toggle_player_behavior(player_hook, can_grapple)

func _on_abilities_changed() -> void:
	if mode != Mode.DEFEATED: _toggle_abilities()

func _handle_game_over() -> void:
	GameState.reset_lives()
	var challenge_start_scene: String = GameState.get_challenge_start_scene()
	if challenge_start_scene.is_empty():
		GameState.set_current_spawn_point(^"")
		SceneSwitcher.reload_with_transition(Transition.Effect.FADE, Transition.Effect.FADE)
	else:
		SceneSwitcher.change_to_file_with_transition(challenge_start_scene, ^"", Transition.Effect.FADE, Transition.Effect.FADE)
		
