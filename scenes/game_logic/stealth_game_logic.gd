# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name StealthGameLogic
extends Node

@export var portal_item: CollectibleItem

var _collected_count: int = 0
var _total_objects: int = 0

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	# Ocultar portal al inicio
	if portal_item:
		portal_item.revealed = false

	# Conectar los 4 coleccionables
	var ritual_objects := get_tree().get_nodes_in_group(&"ritual_object")
	_total_objects = ritual_objects.size()
	for obj in ritual_objects:
		if obj is CollectibleItem:
			obj.tree_exiting.connect(_on_ritual_object_collected)

	# Conectar portal SOLO después de los rituales
	# No conectar tree_exiting del portal aquí, se conecta cuando aparece

	await get_tree().physics_frame
	await get_tree().physics_frame
	for guard in get_tree().get_nodes_in_group(&"guard_enemy"):
		if guard.has_signal("player_detected"):
			if guard.player_detected.is_connected(self._on_player_detected):
				guard.player_detected.disconnect(self._on_player_detected)
			guard.player_detected.connect(self._on_player_detected)
			
func _on_ritual_object_collected() -> void:
	_collected_count += 1
	if _collected_count >= _total_objects:
		if portal_item:
			portal_item.reveal()
			portal_item.tree_exiting.connect(_on_final_object_collected)
			
func _on_final_object_collected() -> void:
	SceneSwitcher.change_to_file_with_transition(
		"res://scenes/quests/story_quests/runa_runner/2_combat/runa_runner_combat.tscn",
		^"", Transition.Effect.FADE, Transition.Effect.FADE
	)
func _on_player_detected(player: Node2D) -> void:
	pass
