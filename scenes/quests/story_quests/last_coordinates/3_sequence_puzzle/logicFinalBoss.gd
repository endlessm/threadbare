# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

var lifes: int = 3
@onready var player: Player = $Underground/Player
@onready var lifesText: Label = $CanvasLayer/lifesText
@onready var tilemap: TileMapLayer = $Tiles/TileMapLayer

@export var squareHurt:PackedScene = preload("uid://c40eyjqxbhrko")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:	
	lifesText.text = str(lifes)
	generar_varios_rayos(180)
	
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
	if lifes == 0:
		player.defeat()
		print("Muerte")
	



# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
