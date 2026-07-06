# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CharacterBody2D

@onready var button_item: ButtonItem = %ButtonItem


func _ready() -> void:
	if not button_item or button_item.is_queued_for_deletion():
		queue_free()


func _on_button_item_collected() -> void:
	queue_free()
