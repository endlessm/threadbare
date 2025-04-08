# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@export var inkwells_to_win: int = 1

var inkwells_completed: int = 0

@onready var on_the_ground: Node2D = %OnTheGround
@onready var collectible_item: CollectibleItem = %CollectibleItem
@onready var player: Player = %Player


func _ready() -> void:
	for node: Node in on_the_ground.get_children():
		if node is not Inkwell:
			continue
		node = node as Inkwell
		node.completed.connect(_on_inkwell_completed)


func _on_inkwell_completed() -> void:
	inkwells_completed += 1
	if inkwells_completed < inkwells_to_win:
		return
	# get_tree().call_group(&"ink_drinkers", &"remove")
	get_tree().call_group("ink_drinkers", "remove")
	player.mode = Player.Mode.COZY
	collectible_item.reveal()
