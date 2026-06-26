# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node
# The Teleporter component needs to be an Area2D so that collision shapes can be
# added as children in each scene using it. But it also needs to be a SceneLink,
# which does not extend Area2D.
#
# In GDScript, if you have a node of type U (e.g. Area2D) which extends T (e.g.
# Node2D), you can attach a script which extends T (in this case SceneLink) to
# it. So then the only missing piece is to connect the Area2D's signals to the
# SceneLink.switch() method, and that's where this script comes in.
#
# If Godot supported traits, or re-exported properties of child nodes, we
# wouldn't need this weird workaround.

@export var teleport_area: Area2D
@export var scene_link: SceneLink


func _connect() -> void:
	# ONE_SHOT to avoid triggering the same teleporter while the transition is running.
	# DEFERRED because otherwise if use_transition is false, switching scene
	# would delete Area2D during a physics callback - bad!
	var flags := CONNECT_ONE_SHOT | CONNECT_DEFERRED
	teleport_area.body_entered.connect(_on_teleport_area_body_entered, flags)


func _on_teleport_area_body_entered(_body: Node2D) -> void:
	await scene_link.switch()
	if not scene_link.next_scene:
		# We didn't change scene - re-enable the teleporter
		_connect()


func _ready() -> void:
	_connect()
