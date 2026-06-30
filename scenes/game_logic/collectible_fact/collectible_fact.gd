# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name CollectibleFact
extends Node
## Persist and restore the collected state of a collectible. For example, a
## [ButtonItem].
##
## Persist one Array per scene file, using the current scene file path as key for
## the fact. And use the collectible node path inside the scene for identifying
## each collectible.

const COLLECTED_SIGNAL_NAME := "collected"

## A node with a signal named [constant COLLECTED_SIGNAL_NAME]. Also if the node has a method named
## "start_collected", it may be called when restoring the game state.
@export var collectible: Node2D:
	set = _set_collectible

var _fact_name: String
var _fact_value: String
var _facts: Dictionary


func _enter_tree() -> void:
	if not collectible and get_parent() is Node2D:
		collectible = get_parent()


func _set_collectible(new_collectible: Node2D) -> void:
	collectible = new_collectible
	if not Engine.is_editor_hint():
		if collectible.is_node_ready():
			_on_collectible_ready()
		else:
			collectible.ready.connect(_on_collectible_ready)
	update_configuration_warnings()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray
	if not collectible:
		warnings.append("Collectible must be set.")
	elif not collectible.has_signal(COLLECTED_SIGNAL_NAME):
		warnings.append("Collectible must have a signal named %s." % COLLECTED_SIGNAL_NAME)
	return warnings


func _get_fact_name() -> String:
	return "collected_in_%s" % get_tree().current_scene.scene_file_path


func _get_fact_dict() -> Dictionary:
	return GameState.quest.facts if GameState.quest else GameState.global.facts


func _on_collectible_ready() -> void:
	if not GameState.persist_progress:
		queue_free()
		return

	_fact_name = _get_fact_name()
	_fact_value = collectible.get_path()
	_facts = _get_fact_dict()

	if _fact_value in _facts.get(_fact_name, []):
		# Restore from saved state:
		if collectible.has_method("start_collected"):
			collectible.start_collected()
		else:
			collectible.visible = false
			collectible.queue_free()
		queue_free()
	else:
		collectible.connect(COLLECTED_SIGNAL_NAME, _on_collectible_collected)


func _on_collectible_collected() -> void:
	# Persist the state:
	if _fact_name not in _facts:
		_facts[_fact_name] = []
	(_facts[_fact_name] as Array).append(_fact_value)
