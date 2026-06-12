# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

var lifes: int = 3
@onready var player: Player = $Underground/Player
@onready var lifesText: Label = $CanvasLayer/lifesText
@onready var tilemap: TileMapLayer = $Tiles/TileMapLayer
@onready var fillGameLocig: FillGameLogic = $FillGameLogic
@onready var playerAnimation: AnimationPlayer = $Underground/Player/PlayerHarm/GotHitAnimation
@export var squareHurt:PackedScene = preload("uid://c40eyjqxbhrko")
@onready var dialogue: Cinematic = $Cinematic
@onready var timer: Timer = $Timer
#@onready var projectile: PackedScene = preload("uid://yqbgsj15hp2m")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	lifesText.text = str(lifes)
	print("Inicio")
	
func generar_rayo() -> void:
	var rayo: Node = squareHurt.instantiate()
	
	var celdas: Array[Vector2i] = tilemap.get_used_cells()
	var celda: Variant = celdas.pick_random()
	rayo.global_position = tilemap.to_global(tilemap.map_to_local(celda))

	#await get_tree().create_timer(2.0).timeout
	add_child(rayo)
	rayo.daño.connect(logicLife)

func generar_varios_rayos(cantidad:int) -> void:
	for i in cantidad:
		generar_rayo()

func logicLife() -> void:
	lifes -=1
	lifesText.text = str(lifes)
	print(lifes)
	playerAnimation.play(&"got_hit")
	CameraShake.shake()
	if lifes == 0:
		GameState.intro_dialogue_shown = false
		player.defeat()
		#fillGameLocig.start()
		#timer.start()
		print("Muerte")

func final() -> void:
	#EN PROCESO
	SceneSwitcher.change_to_file_with_transition("uid://ccvtfhl2daoum")
	print("Final")

func cinematic() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(%CanvasModulate, "color", Color("d3d3d3ff"), 2.5)
	print("Se hizo la luz")

func _on_timer_timeout()-> void :
	generar_varios_rayos(10) # Replace with function body.
