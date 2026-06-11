extends Node2D

@export var zones: Array[CorruptionZone]

@onready var collectible_item: CollectibleItem = $"../CollectibleItem"

@onready var player: Player = $"../CorruptionPlayer"

@onready var timer_label = $"../../HUD/CorruptionHUD/VBoxContainer/TimerLabel"

@onready var north_label = $"../../HUD/CorruptionHUD/VBoxContainer/NorthLabel"
@onready var south_label = $"../../HUD/CorruptionHUD/VBoxContainer/SouthLabel"
@onready var east_label = $"../../HUD/CorruptionHUD/VBoxContainer/EastLabel"
@onready var west_label = $"../../HUD/CorruptionHUD/VBoxContainer/WestLabel"

var current_zone: CorruptionZone
var player_was_inside := {}
var game_started: bool = false
var game_time: float = 90.0
var last_second := 90
var game_finished: bool = false


func _ready() -> void:

	for zone in zones:
		player_was_inside[zone] = false
	if GameState.intro_dialogue_shown:
		start_game()
	else:
		print("Waiting for dialogue...")


func _process(delta: float) -> void:
	if not game_started:
		return

	if game_finished:
		return

	game_time -= delta
	
	if int(game_time) != last_second:
		last_second = int(game_time)
		print("Time Left: ", last_second)
	
	if game_time <= 0:
		win_game()
		return
	
	if current_zone:
		current_zone.increase_corruption(delta * 5.0)

	for zone in zones:
		if zone.corruption >= 100.0:
			lose_game()
			return
		if zone.player_inside:
			zone.decrease_corruption(delta * 10.0)

		var was_inside = player_was_inside[zone]

		if zone.player_inside and not was_inside:

			print("Player discovered ", zone.name)

			if zone == current_zone:
				zone.altar.set_corrupted(false)
				
				print("Shadow escaped!")

				select_random_zone()

		player_was_inside[zone] = zone.player_inside
		update_hud()


func select_random_zone() -> void:
	if zones.is_empty():
		return

	var available_zones := zones.filter(
		func(zone):
			return zone != current_zone
	)

	if available_zones.is_empty():
		return

	current_zone = available_zones.pick_random()
	current_zone.altar.set_corrupted(true)

	print("Corrupting: ", current_zone.name)

func start_game() -> void:
	game_started = true
	select_random_zone()

	print("GAME STARTED")

func _on_cinematic_cinematic_finished() -> void:
	start_game()
	
func win_game() -> void:
	game_finished = true

	print("YOU WIN!")
	collectible_item.reveal()
func lose_game() -> void:
	game_finished = true
	
	print("GAME OVER!")
	
	player.defeat()


func update_hud() -> void:

	timer_label.text = "Time: " + str(int(game_time))

	north_label.text = "North: " + str(int(zones[0].corruption)) + "%"
	south_label.text = "South: " + str(int(zones[1].corruption)) + "%"
	east_label.text = "East: " + str(int(zones[2].corruption)) + "%"
	west_label.text = "West: " + str(int(zones[3].corruption)) + "%"
