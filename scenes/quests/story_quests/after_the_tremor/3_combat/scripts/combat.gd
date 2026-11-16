# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@onready var boss = $Boss
@onready var boss_health = $BossHealth
@onready var collectible = $CollectibleItem

@onready var charlie = $PlayersContainer/charlie
@onready var bryan = $PlayersContainer/bryan

@onready var tile_grass = $TileMapLayers/Grass
@onready var tile_stones = $TileMapLayers/Stones2

@onready var music = $Music
@onready var win_sound = $WinSound 
@onready var boss_info = $UI/BossInfo
@onready var health_bar = $UI/BossInfo/BossBar 

@onready var player_mode: PlayerMode = %PlayerMode

func _ready():
	if collectible:
		collectible.revealed = false
		collectible.visible = false 
	
	if boss_health:
		boss_health.completed.connect(_on_boss_defeated)
		
		if boss_health.has_signal("hp_changed"):
			boss_health.hp_changed.connect(_update_health_bar)
		
		if health_bar:
			health_bar.max_value = boss_health.needed_amount
			health_bar.value = boss_health.needed_amount
	
	if boss: boss.start()
	if charlie: _setup_combat_player(charlie)
	if bryan: _setup_combat_player(bryan)
	if music and not music.playing: music.play()

func _setup_combat_player(p_node):
	p_node.speeds.walk_speed = 0.0
	p_node.speeds.run_speed = 0.0


func _update_health_bar(current_damage_taken):
	if health_bar:
		health_bar.value = health_bar.max_value - current_damage_taken

func _on_boss_defeated():
	print("¡Nivel completado!")
	if music: music.stop()
	if win_sound: win_sound.play()
	if boss: boss.remove()
	if collectible: collectible.reveal(); collectible.visible = true
	if tile_grass: tile_grass.modulate = Color.WHITE
	if tile_stones: tile_stones.modulate = Color.WHITE
	
	player_mode.mode = PlayerMode.Mode.COZY

	if boss_info:
		boss_info.visible = false
	if charlie:
		var sprite = charlie.get_node_or_null("PlayerSprite") 
		if not sprite: sprite = charlie.find_child("AnimatedSprite2D", true, false)
		if sprite: sprite.play("idle"); sprite.stop()

	if bryan:
		bryan.speeds.walk_speed = 300.0
		bryan.speeds.run_speed = 500.0
