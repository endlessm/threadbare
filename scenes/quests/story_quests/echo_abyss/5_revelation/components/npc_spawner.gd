# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D
class_name EchoAbyssNpcSpawner

@export var wandering_npc_scene: PackedScene = preload("res://scenes/quests/story_quests/echo_abyss/5_revelation/components/wandering_npc.tscn")
@export var max_npcs: int = 5
@export var spawn_interval: float = 8.0
@export var spawn_area_min: Vector2 = Vector2(-400, 100)
@export var spawn_area_max: Vector2 = Vector2(800, 600)
@export var npc_sprites: Array[SpriteFrames] = []

var _spawn_timer: Timer

func _ready() -> void:
	if Engine.is_editor_hint():
		return
		
	# Setup spawn timer
	_spawn_timer = Timer.new()
	_spawn_timer.wait_time = spawn_interval
	_spawn_timer.autostart = true
	_spawn_timer.timeout.connect(_on_spawn_timeout)
	add_child(_spawn_timer)
	
	# Spawn initial batch
	for i in range(max_npcs):
		_spawn_npc()

func _on_spawn_timeout() -> void:
	var active_npcs = get_tree().get_nodes_in_group("wandering_npc")
	# Count only valid, non-queued-for-deletion NPCs
	var count = 0
	for npc in active_npcs:
		if is_instance_valid(npc) and not npc.is_queued_for_deletion():
			count += 1
			
	if count < max_npcs:
		_spawn_npc()

func _spawn_npc() -> void:
	if not wandering_npc_scene:
		return
		
	var npc = wandering_npc_scene.instantiate() as EchoAbyssWanderingNpc
	if not npc:
		return
		
	# Pick random position
	var spawn_pos = Vector2(
		randf_range(spawn_area_min.x, spawn_area_max.x),
		randf_range(spawn_area_min.y, spawn_area_max.y)
	)
	
	# If navigation map is available, align to navigation map
	if is_inside_tree():
		var nav_map = get_world_2d().navigation_map
		var closest_point = NavigationServer2D.map_get_closest_point(nav_map, spawn_pos)
		# Only use closest point if it's within a reasonable distance to avoid spawning way outside
		if spawn_pos.distance_to(closest_point) < 200.0:
			spawn_pos = closest_point
			
	npc.global_position = spawn_pos
	
	# Assign random sprite if available
	if not npc_sprites.is_empty():
		npc.sprite_frames = npc_sprites.pick_random()
		
	# Add to Ground node for Y-sorting (parent or grandparent or siblings of spawner)
	# Usually we add it to the same parent as the spawner (e.g. OnTheGround)
	get_parent().add_child(npc)
