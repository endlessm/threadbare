# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Node2D
# TODO: Change to item you want to walk past (in inspector)
# TODO: we also would need tree to have a class_name or some other way to generalize this
const TREE_SCENE = preload("res://scenes/game_elements/props/tree/components/tree.gd")

@export_range(10, 1000, 10) var width: float = 200.0:
	set(val):
		if walkable_trees:
			for shape in walkable_trees.get_children():
				shape.shape.size.x = val
			l_border.position.x -= (val - width) / 2
			r_border.position.x += (val - width) / 2
			width = val

@export_range(10, 1000, 10) var height: float = 400.0:
	set(val):
		if walkable_trees:
			for shape in walkable_trees.get_children():
				shape.shape.size.y = val
			l_border.shape.size.y += (val - height) / 2
			r_border.shape.size.y += (val - height) / 2
			height = val

var trees: Array[Node2D]
var colliders: Array[Node2D]

@onready var walkable_trees: Area2D = $WalkableTrees
@onready var l_border: CollisionShape2D = $Borders/LeftBorder
@onready var r_border: CollisionShape2D = $Borders/RightBorder
# TODO: Give audio stream a leaf rustle sound
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		for tree in trees:
			tree.process_mode = Node.PROCESS_MODE_DISABLED
			tree.get_parent().modulate = Color(.6, .6, .6, 0.3)
		audio_stream_player_2d.play()
		for collider in colliders:
			collider.process_mode = Node.PROCESS_MODE_DISABLED
	elif body.get_parent().get_script() == TREE_SCENE:
		trees.append(body)
	else:
		colliders.append(body)


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		for tree in trees:
			tree.process_mode = Node.PROCESS_MODE_INHERIT
			tree.get_parent().modulate = Color(1, 1, 1)
		for collider in colliders:
			collider.process_mode = Node.PROCESS_MODE_INHERIT
