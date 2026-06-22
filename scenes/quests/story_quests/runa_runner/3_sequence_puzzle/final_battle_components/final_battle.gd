# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name RunaRunnerFinalBattle
extends Node2D

@export var projectile_scene: PackedScene
@export_file("*.tscn") var next_scene: String = "res://scenes/quests/story_quests/runa_runner/4_outro/OutroCinematica.tscn"
@export var max_player_health: float = 100.0
@export var final_health_threshold: float = 18.0
@export var survival_time: float = 34.0
@export var projectile_speed: float = 260.0
@export var entity_move_speed: float = 115.0
@export var arena_min: Vector2 = Vector2(32, 32)
@export var arena_max: Vector2 = Vector2(1360, 900)
@export var rope_anchor: Vector2 = Vector2(704, 460)
@export var rope_pull_distance: float = 190.0

var _player_health: float = 100.0
var _battle_time: float = 0.0
var _projectile_timer: float = 1.0
var _damage_cooldown: float = 0.0
var _rope_cooldown: float = 0.0
var _blade_cooldown: float = 0.0
var _pattern_index: int = -1
var _battle_finished: bool = false
var _entity_start_position: Vector2
var _entity_move_target: Vector2
var _entity_move_timer: float = 0.0
var _entity_attack_timer: float = 0.0
var _entity_patrol_index: int = 0
var _entity_patrol_points: Array[Vector2] = []

@onready var player: Player = $OnTheGround/Player as Player
@onready var entity: Node2D = $OnTheGround/MysteriousEntity
@onready var entity_sprite: AnimatedSprite2D = $OnTheGround/MysteriousEntity/EntitySprite
@onready var projectile_parent: Node2D = $Projectiles
@onready var player_health_bar: ProgressBar = $BattleHUD/PlayerHealthBar
@onready var instruction_label: Label = $BattleHUD/InstructionLabel
@onready var white_out: ColorRect = $BattleHUD/WhiteOut
@onready var rope_line: Line2D = $RopeLine
@onready var blade_slash: Line2D = $BladeSlash


func _ready() -> void:
	_player_health = max_player_health
	_entity_start_position = entity.position
	_entity_move_target = entity.position
	_entity_patrol_points = [
		Vector2(1060, 260),
		Vector2(1220, 430),
		Vector2(980, 650),
		Vector2(760, 520),
		Vector2(1120, 760),
	]
	player_health_bar.max_value = max_player_health
	_update_health_bar()
	white_out.visible = false
	rope_line.visible = false
	blade_slash.visible = false
	_play_entity_animation(&"idle")
	instruction_label.text = "Sobrevive a la entidad | Z bloquea | X hoja | Espacio cuerda"


func _physics_process(delta: float) -> void:
	if _battle_finished:
		return

	_battle_time += delta
	_projectile_timer -= delta
	_damage_cooldown = maxf(0.0, _damage_cooldown - delta)
	_rope_cooldown = maxf(0.0, _rope_cooldown - delta)
	_blade_cooldown = maxf(0.0, _blade_cooldown - delta)
	_entity_attack_timer = maxf(0.0, _entity_attack_timer - delta)

	_update_entity_motion(delta)
	_handle_player_tools()
	_clamp_player_to_arena()

	if _projectile_timer <= 0.0:
		_fire_next_pattern()

	if _battle_time >= survival_time:
		_start_white_out()


func _handle_player_tools() -> void:
	if Input.is_action_pressed(&"repel"):
		player.modulate = Color(0.72, 0.86, 1.0)
	elif _damage_cooldown <= 0.0:
		player.modulate = Color.WHITE

	if Input.is_action_just_pressed(&"throw") and _blade_cooldown <= 0.0:
		_use_blade()

	if Input.is_action_just_pressed(&"interact") and _rope_cooldown <= 0.0:
		_use_rope()


func _use_blade() -> void:
	_blade_cooldown = 0.75
	blade_slash.visible = true
	blade_slash.points = PackedVector2Array(
		[
			player.global_position + Vector2(-58, -18),
			player.global_position + Vector2(12, -52),
			player.global_position + Vector2(70, -12),
		]
	)
	_clear_projectiles_near(player.global_position, 105.0)
	if player.global_position.distance_to(entity.global_position) <= 140.0:
		_stagger_entity()
		_battle_time += 1.25
	await get_tree().create_timer(0.12).timeout
	if is_instance_valid(blade_slash):
		blade_slash.visible = false


func _use_rope() -> void:
	_rope_cooldown = 1.15
	rope_line.visible = true
	rope_line.points = PackedVector2Array([player.global_position, rope_anchor])
	player.global_position = _clamp_to_arena(
		player.global_position.move_toward(rope_anchor, rope_pull_distance)
	)
	await get_tree().create_timer(0.16).timeout
	if is_instance_valid(rope_line):
		rope_line.visible = false


func _update_entity_motion(delta: float) -> void:
	_entity_move_timer = maxf(0.0, _entity_move_timer - delta)
	if _entity_move_timer <= 0.0 or entity.position.distance_to(_entity_move_target) <= 10.0:
		_choose_next_entity_target()

	entity.position = entity.position.move_toward(_entity_move_target, entity_move_speed * delta)
	entity_sprite.position.y = -26.0 + sin(_battle_time * 2.7) * 5.0
	entity_sprite.rotation = sin(_battle_time * 4.4) * 0.04
	entity_sprite.flip_h = player.global_position.x < entity.global_position.x
	if _entity_attack_timer > 0.0:
		_play_entity_animation(&"attack")
	elif entity.position.distance_to(_entity_move_target) > 12.0:
		_play_entity_animation(&"move")
	else:
		_play_entity_animation(&"idle")


func _play_entity_animation(animation_name: StringName) -> void:
	if entity_sprite.animation == animation_name and entity_sprite.is_playing():
		return
	entity_sprite.play(animation_name)


func _choose_next_entity_target() -> void:
	if _entity_patrol_points.is_empty():
		_entity_move_target = _entity_start_position
		return

	_entity_patrol_index = (_entity_patrol_index + 1) % _entity_patrol_points.size()
	_entity_move_target = _clamp_to_arena(_entity_patrol_points[_entity_patrol_index])
	_entity_move_timer = 2.3


func _fire_next_pattern() -> void:
	_pattern_index = (_pattern_index + 1) % 3
	_entity_attack_timer = 0.55
	_play_entity_animation(&"attack")
	match _pattern_index:
		0:
			_fire_aimed_fan()
			_projectile_timer = 1.25
		1:
			_fire_energy_ring()
			_projectile_timer = 1.55
		2:
			_fire_side_waves()
			_projectile_timer = 1.7


func _fire_aimed_fan() -> void:
	var base_direction: Vector2 = entity.global_position.direction_to(player.global_position)
	var spreads: Array[float] = [-0.34, -0.17, 0.0, 0.17, 0.34]
	for index: int in range(spreads.size()):
		var shot_angle: float = spreads[index]
		_spawn_projectile(
			entity.global_position,
			base_direction.rotated(shot_angle),
			projectile_speed + 25.0,
			16.0
		)


func _fire_energy_ring() -> void:
	var count: int = 14
	var angle_offset: float = _battle_time * 0.55
	for index: int in range(count):
		var angle: float = TAU * float(index) / float(count) + angle_offset
		_spawn_projectile(entity.global_position, Vector2.RIGHT.rotated(angle), projectile_speed, 13.0)


func _fire_side_waves() -> void:
	var lanes: int = 6
	for index: int in range(lanes):
		var weight: float = float(index) / float(lanes - 1)
		var y_position: float = lerpf(arena_min.y + 92.0, arena_max.y - 92.0, weight)
		_spawn_projectile(Vector2(arena_min.x, y_position), Vector2.RIGHT, projectile_speed + 10.0, 14.0)
		_spawn_projectile(
			Vector2(arena_max.x, y_position + sin(_battle_time + float(index)) * 28.0),
			Vector2.LEFT,
			projectile_speed + 10.0,
			14.0
		)


func _spawn_projectile(
	start_position: Vector2, direction: Vector2, speed: float, damage: float
) -> void:
	if projectile_scene == null:
		return
	var instance: Node = projectile_scene.instantiate()
	var projectile: RunaRunnerFinalEnergyProjectile = instance as RunaRunnerFinalEnergyProjectile
	if projectile == null:
		instance.queue_free()
		return
	projectile_parent.add_child(projectile)
	projectile.setup(start_position, direction, speed, damage)
	projectile.hit_player.connect(_on_projectile_hit_player)


func _on_projectile_hit_player(projectile: RunaRunnerFinalEnergyProjectile) -> void:
	if _battle_finished or _damage_cooldown > 0.0:
		return
	_damage_cooldown = 0.36
	var damage_amount: float = projectile.damage
	if Input.is_action_pressed(&"repel"):
		damage_amount *= 0.35
	_apply_player_damage(damage_amount)


func _apply_player_damage(amount: float) -> void:
	_player_health = maxf(0.0, _player_health - amount)
	_update_health_bar()
	player.modulate = Color(1.0, 0.58, 0.58)
	var tween: Tween = create_tween()
	tween.tween_property(player, "modulate", Color.WHITE, 0.22)
	if _player_health <= final_health_threshold:
		_start_white_out()


func _update_health_bar() -> void:
	player_health_bar.value = _player_health


func _clear_projectiles_near(origin: Vector2, radius: float) -> int:
	var cleared: int = 0
	for child: Node in projectile_parent.get_children():
		var projectile: Node2D = child as Node2D
		if projectile == null:
			continue
		if projectile.global_position.distance_to(origin) <= radius:
			projectile.queue_free()
			cleared += 1
	return cleared


func _stagger_entity() -> void:
	entity_sprite.modulate = Color(0.85, 1.0, 1.0)
	var tween: Tween = create_tween()
	tween.tween_property(entity_sprite, "modulate", Color.WHITE, 0.18)


func _clamp_player_to_arena() -> void:
	player.global_position = _clamp_to_arena(player.global_position)


func _clamp_to_arena(position_to_clamp: Vector2) -> Vector2:
	return Vector2(
		clampf(position_to_clamp.x, arena_min.x, arena_max.x),
		clampf(position_to_clamp.y, arena_min.y, arena_max.y)
	)


func _start_white_out() -> void:
	if _battle_finished:
		return
	_battle_finished = true
	instruction_label.text = "El tiempo se detiene..."
	for child: Node in projectile_parent.get_children():
		child.queue_free()
	if is_instance_valid(player):
		player.mode = Player.Mode.SYSTEM_CONTROLLED
		player.velocity = Vector2.ZERO
	white_out.visible = true
	white_out.color = Color(1.0, 1.0, 1.0, 0.0)
	var tween: Tween = create_tween()
	tween.tween_property(white_out, "color", Color.WHITE, 1.45)
	tween.parallel().tween_property(entity, "modulate", Color(1.0, 1.0, 1.0, 0.0), 1.0)
	await tween.finished
	await get_tree().create_timer(0.8).timeout
	if not next_scene.is_empty():
		SceneSwitcher.change_to_file(next_scene)
