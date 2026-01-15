# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends VBoxContainer

@export var studios: Array[CreditsStudio]:
	set = set_studios

@export var studio_view_scene: PackedScene


func set_studios(new_value: Array[CreditsStudio]) -> void:
	studios = new_value

	if not is_node_ready():
		return

	for child: Node in get_children():
		remove_child(child)
		child.queue_free()

	for studio: CreditsStudio in studios:
		var studio_view := studio_view_scene.instantiate()
		studio_view.studio = studio
		add_child(studio_view)


func _ready() -> void:
	set_studios(studios)
