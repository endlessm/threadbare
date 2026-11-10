# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name ZoneActivation
extends Node
## Define a zone of the world map in a level scene, that can be activated.
##
## The only definition of a zone is its name, and the activation is used to display the zone name in
## the game HUD.
##
## It can be defined using an Area2D with one or more collision shapes that the player must cross to
## activate the zone, like a bridge. Or with SpawnPoint nodes, so when the player is teleported to
## this level, the zone is activated.

@export var zone_name_text: String
@export var area: Area2D
@export var spawn_points: Array[SpawnPoint]


func _ready() -> void:
	if area:
		area.body_entered.connect(_on_body_entered)
	for s in spawn_points:
		s.player_teleported.connect(entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	entered()


func entered() -> void:
	GameState.global.zone_entered(zone_name_text)
