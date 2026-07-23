# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Control


# Called when the node enters the scene tree for the first time.

func _ready() -> void:
	$AnimationPlayer.play("outro")

	pass  # Replace with function body.
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://scenes/world_map/frays_end.tscn")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass

	
