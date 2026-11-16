# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Area2D
## An area inside which the player is set to mode [member Player.Mode.COZY],
## and outside which is set to mode [member Player.Mode.HOOKING].
##
## This is a hack for collecting a thread in a grappling hook scene,
## until we get rid of player modes.


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if not player:
		return
	player.mode = Player.Mode.COZY


func _on_body_exited(body: Node2D) -> void:
	var player := body as Player
	if not player:
		return
	player.mode = Player.Mode.HOOKING
