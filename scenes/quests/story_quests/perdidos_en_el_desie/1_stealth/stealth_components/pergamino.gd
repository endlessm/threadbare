# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

signal recolectado

@export var collected_dialogue: DialogueResource
@export var dialogue_title: StringName = &"start"

@onready var interact_area: InteractArea = $InteractArea
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animated_sprite: AnimatedSprite2D = $InteractArea/AnimatedSprite2D


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	interact_area.action = "Leer pergamino"
	if animated_sprite:
		animated_sprite.play(&"flotando")
	interact_area.interaction_started.connect(_on_interacted)
	add_to_group(&"pergaminos")


func _on_interacted(player: Player, _from_right: bool) -> void:
	z_index += 1

	if animation_player:
		animation_player.play(&"collected")
		await animation_player.animation_finished

	if collected_dialogue:
		DialogueManager.show_dialogue_balloon(
			collected_dialogue,
			dialogue_title,
			[self, player]
		)
		await DialogueManager.dialogue_ended

	interact_area.end_interaction()
	recolectado.emit()
	queue_free()
