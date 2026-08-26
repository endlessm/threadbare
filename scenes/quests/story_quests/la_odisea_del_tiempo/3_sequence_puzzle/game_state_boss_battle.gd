# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node
@export var muros_tiles :TileMapLayer

func _ready() -> void:
	
	pass 


func _close_path()-> void:
	muros_tiles.set_cell(Vector2i(-5,5),0,Vector2i(0,1),0)
	muros_tiles.set_cell(Vector2i(-5,6),0,Vector2i(0,1),0)
	muros_tiles.set_cell(Vector2i(-5,7),0,Vector2i(0,1),0)
	
