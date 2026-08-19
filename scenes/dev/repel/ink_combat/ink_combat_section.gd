# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0

## This logic is *not* needed to add Ink Combat to your level. Simply
## grab the ThrowingEnemy and FillingBarrel nodes and copy them to
## your scene. This logic helps with sectioning off each part of Ink Combat.
extends Node2D

var _barrels: Array[FillingBarrel]
var _enemies: Array[ThrowingEnemy]

@onready var enemy_container: Node2D = $Enemies
@onready var barrel_container: Node2D = $Barrels


func _ready() -> void:
	for barrel: FillingBarrel in barrel_container.get_children():
		var barrel_copy := barrel.duplicate()
		_barrels.append(barrel_copy)
	for enemy: ThrowingEnemy in enemy_container.get_children():
		var enemy_copy := enemy.duplicate()
		_enemies.append(enemy_copy)


## Add fresh duplicate nodes to the scene tree and
## corresponding groups to replace the ones depleted
## in ink combat.
func reset() -> void:
	for enemy: ThrowingEnemy in enemy_container.get_children():
		if is_instance_valid(enemy):
			enemy_container.remove_child(enemy)
			enemy.queue_free()
			enemy.call_deferred("free")

	for enemy: ThrowingEnemy in _enemies:
		var new_enemy := enemy.duplicate()
		enemy_container.call_deferred("add_child", new_enemy)
		new_enemy.add_to_group("throwing_enemy")

	for barrel: FillingBarrel in barrel_container.get_children():
		if is_instance_valid(barrel):
			barrel.free()

	for barrel: FillingBarrel in _barrels:
		var new_barrel := barrel.duplicate()
		barrel_container.add_child(new_barrel)
		new_barrel.add_to_group("filling_barrels")
