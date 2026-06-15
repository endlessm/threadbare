# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@export var lifes: int = 5:
	set(life):
		lifes = life
@export var nRayos: int = 10:
	set(rayo):
		nRayos = rayo

@onready var player: Player = $Underground/Player
@onready var lifesText: Label = $CanvasLayer/HBoxContainer/TextureRect/lifesText
@onready var tilemap: TileMapLayer = $Tiles/TileMapLayer
@onready var fillGameLocig: FillGameLogic = $FillGameLogic
@onready var playerAnimation: AnimationPlayer = $Underground/Player/PlayerHarm/GotHitAnimation
@export var squareHurt:PackedScene = preload("uid://cu7r1r0afhvgj")
@onready var timer: Timer = $Timer
@onready var cinematicFinal: Cinematic = $CinematicFinal
@onready var timerDanger:Timer = $TimerDanger
@onready var textDanger: Label = $TextDanger
@onready var enemy :ThrowingEnemy = $Underground/ThrowingEnemy
var finalBarrel: bool = false
#@onready var projectile: PackedScene = preload("uid://yqbgsj15hp2m")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	lifesText.text = "x" + str(lifes)
	print("Inicio")
	
#Funcion que genera lasers aleatorios de acuerdo al tilemap puesto
func generateLaser() -> void:
	if finalBarrel == false:
		var rayo: Node = squareHurt.instantiate()
		var celdas: Array[Vector2i] = tilemap.get_used_cells()
		var celda: Variant = celdas.pick_random()
		rayo.global_position = tilemap.to_global(tilemap.map_to_local(celda))
		add_child(rayo)
		rayo.daño.connect(logicLife)
	pass
	

func generateLasers(cantidad:int) -> void:
	for i in cantidad:
		generateLaser()

func moreLaser() -> void:
	CameraShake.shake()
	%soundWarning.play()
	textDanger.visible = true
	parpadear()
	timerDanger.start()

func parpadear() -> void:
	var tween: Tween = create_tween()
	tween.set_loops()

	tween.tween_property(textDanger, "modulate:a", 0.0, 0.5)
	tween.tween_property(textDanger, "modulate:a", 1.0, 0.5)

func logicLife() -> void:
	lifes -=1
	print(lifes)
	playerAnimation.play(&"got_hit")
	CameraShake.shake()
	if lifes == 0:
		GameState.intro_dialogue_shown = false
		player.defeat()
		print("Muerte")
	lifesText.text = "x" + str(lifes)

func final() -> void:
	finalBarrel = true
	GameState.intro_dialogue_shown = false
	cinematicFinal.start()
	timer.stop()
	#SceneSwitcher.change_to_file_with_transition("uid://ccvtfhl2daoum")
	print("Final")

func cinematic() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(%CanvasModulate, "color", Color("d3d3d3ff"), 2.5)
	print("Se hizo la luz")

func _on_timer_timeout() -> void :
	if finalBarrel == false:
		generateLasers(nRayos)
	pass

func _on_timer_danger_timeout() -> void:
	if finalBarrel == false:
		textDanger.visible = false
		generateLasers(100)
		nRayos +=10
		%soundWarning.stop()
	pass
	
