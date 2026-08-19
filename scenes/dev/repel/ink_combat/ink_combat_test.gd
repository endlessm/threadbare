# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0

## This logic is *not* needed to add Ink Combat to your level. Simply
## grab the ThrowingEnemy and FillingBarrel nodes and copy them to
## your scene. This logic helps with sectioning off each part of Ink Combat.
extends Node2D

## Index representing the section of Ink Combat currently active.
var _current_section: Node2D

@onready var sections: Node2D = %Sections
@onready var fill_game_logic: FillGameLogic = %FillGameLogic
@onready var barrel_unlock_sequence: BarrelUnlockSequence = %BarrelUnlockSequence
@onready var fragile_logic: Node2D = %FragileLogic


## Start the fill game of the first section
func _ready() -> void:
	_current_section = sections.get_child(0)
	_set_group()
	fill_game_logic.start()


## Use index of section to add and remove ThrowingEnemy and
## FillingBarrel from their groups before starting the
## ink combat sequence.
func set_section(selection: int) -> void:
	_current_section = sections.get_child(selection)
	for section in sections.get_children():
		section.call_deferred("reset")

	# Cooldown between reset and start
	await get_tree().create_timer(2).timeout

	_refresh_fill_logic()
	_set_group()

	# The third section (index 2) uses Fragile Barrels
	if _current_section == sections.get_child(2):
		fragile_logic.setup()

	# The last section (index 3) uses BarrelUnlockSequence
	if _current_section == sections.get_child(3):
		barrel_unlock_sequence.barrels = []
		for barrel in get_tree().get_nodes_in_group("filling_barrels"):
			barrel_unlock_sequence.barrels.append(barrel)
		barrel_unlock_sequence.current_target_index = 0
		barrel_unlock_sequence.start_sequence()

	fill_game_logic.call_deferred("start")


## Connect all "fresh" FillingBarrels to the FillGameLogic.
## Uses same logic as _ready() for fill_game_logic.gd
func _refresh_fill_logic() -> void:
	fill_game_logic.barrels_to_win = _current_section.get_child(1).get_children().size()
	fill_game_logic.barrels_completed = 0

	var filling_barrels: Array = get_tree().get_nodes_in_group("filling_barrels")
	fill_game_logic.barrels_to_win = clampi(
		fill_game_logic.barrels_to_win, 0, filling_barrels.size()
	)
	for barrel: FillingBarrel in filling_barrels:
		if not barrel.is_connected("completed", fill_game_logic._on_barrel_completed):
			barrel.completed.connect(fill_game_logic._on_barrel_completed)


## Remove all unused ThrowingEnemy and FillingBarrel nodes
## from group, while adding the selected section.
func _set_group() -> void:
	for section: Node2D in sections.get_children():
		if section != _current_section:
			for throwing_enemy: ThrowingEnemy in section.get_child(0).get_children():
				throwing_enemy.remove_from_group("throwing_enemy")
			for barrel: FillingBarrel in section.get_child(1).get_children():
				barrel.remove_from_group("filling_barrels")
		else:
			for throwing_enemy: ThrowingEnemy in section.get_child(0).get_children():
				throwing_enemy.add_to_group("throwing_enemy")
			for barrel: FillingBarrel in section.get_child(1).get_children():
				barrel.add_to_group("filling_barrels")
