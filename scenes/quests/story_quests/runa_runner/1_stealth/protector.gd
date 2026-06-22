# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name Protector
extends StaticBody2D

## Dialogue resource with "npc_agradece" and "portal_susto" nodes.
@export var dialogue: DialogueResource

## Scene to load after the portal sequence (the "second game" / outro).
@export_file("*.tscn") var next_scene: String

@onready var interact_area: InteractArea = $InteractArea

func _ready() -> void:
	interact_area.interaction_started.connect(_on_interacted)

func _on_interacted(player: Player, _from_right: bool) -> void:
	# 1. Agradecimiento del Protector
	DialogueManager.show_dialogue_balloon(dialogue, "npc_agradece", [self, player])
	await DialogueManager.dialogue_ended
	interact_area.end_interaction()

	# 2. Fade a negro
	var fade := ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.z_index = 4096
	get_tree().root.add_child(fade)

	var tween: Tween = create_tween()
	tween.tween_property(fade, "color:a", 1.0, 1.0)
	await tween.finished

	# 3. Grito del protagonista, ya en negro
	DialogueManager.show_dialogue_balloon(dialogue, "portal_susto", [self, player])
	await DialogueManager.dialogue_ended

	# 4. Cambiar a la escena del outro
	if not next_scene.is_empty():
		SceneSwitcher.change_to_file(next_scene)
