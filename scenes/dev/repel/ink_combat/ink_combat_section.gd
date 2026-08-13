# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0

## This logic is *not* needed to add Ink Combat to your level. Simply
## grab the ThrowingEnemy and FillingBarrel nodes and copy them to
## your scene. This logic helps with sectioning off each part of Ink Combat.
extends Node2D

var _barrels: Array[FillingBarrel]
var _enemies: Array[ThrowingEnemy]


func _ready() -> void:
	_update_barrels()
	_update_enemies()


## Store a copy of the FillinBarrel nodes before
## any changes occur during ink combat.
func _update_barrels() -> void:
	for barrel: FillingBarrel in get_child(1).get_children():
		var barrel_copy := barrel.duplicate()
		_barrels.append(barrel_copy)


## Store a copy of the ThrowingEnemy nodes before
## any changes occur during ink combat.
func _update_enemies() -> void:
	_enemies = []
	for enemy: ThrowingEnemy in get_child(0).get_children():
		var enemy_copy := enemy.duplicate()
		_enemies.append(enemy_copy)


## Add fresh duplicate nodes to the scene tree and
## corresponding groups to replace the ones depleted
## in ink combat.
func reset() -> void:
	for enemy: ThrowingEnemy in get_child(0).get_children():
		if is_instance_valid(enemy):
			enemy.call_deferred("free")

	for enemy: ThrowingEnemy in _enemies:
		get_child(0).call_deferred("add_child", enemy)
		enemy.add_to_group("throwing_enemy")

	for barrel: FillingBarrel in get_child(1).get_children():
		if is_instance_valid(barrel):
			barrel.free()

	for barrel: FillingBarrel in _barrels:
		get_child(1).add_child(barrel)
		barrel.add_to_group("filling_barrels")

	_barrels = []
	_update_barrels()
	# Enemies must be deferred, to avoid errors
	# with the attack animation flushing.
	call_deferred("_update_enemies")
