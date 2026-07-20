# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name Cinematic
extends SceneLink
## Shows a dialogue, then transitions to another scene.
##
## Intended for use in non-interactive cutscenes, such as the intro and outro to a quest.
## It can also be used as an easy way to display dialogue at the beginning of a level.

## Emitted when the cinematic has finished. Use it if not passing [member next_scene]
## when you need to do something else after the cinematic.
signal cinematic_finished

## Dialogue for cinematic scene.
@export var dialogue: DialogueResource = preload("uid://b7ad8nar1hmfs"):
	set = set_dialogue

## Title within [member dialogue] to play. If empty, start at the top of [member dialogue].
@export var dialogue_title: String = "":
	set = set_dialogue_title

## Optional animation player, to be used from [member dialogue] (if needed).
@export var animation_player: AnimationPlayer

## Whether to automatically start the cinematic.
@export var autostart: bool = true


func _ready() -> void:
	super._ready()

	if Engine.is_editor_hint():
		return

	if autostart:
		start()


func _validate_property(property: Dictionary) -> void:
	super._validate_property(property)
	match property.name:
		"dialogue_title":
			if dialogue:
				property.hint = PROPERTY_HINT_ENUM
				property.hint_string = ",".join(dialogue.get_titles())
			else:
				property.usage |= PROPERTY_USAGE_READ_ONLY


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := super._get_configuration_warnings()
	if dialogue and dialogue_title and dialogue_title not in dialogue.get_titles():
		warnings.append("Dialogue Title '%s' does not exist" % dialogue_title)
	return warnings


func _dialogue_changed_cb() -> void:
	notify_property_list_changed()
	update_configuration_warnings()


#region Setters
func set_dialogue(new_value: DialogueResource) -> void:
	if dialogue and dialogue.changed.is_connected(_dialogue_changed_cb):
		dialogue.changed.disconnect(_dialogue_changed_cb)
	dialogue = new_value
	if dialogue:
		dialogue.changed.connect(_dialogue_changed_cb)
	_dialogue_changed_cb()


func set_dialogue_title(new_value: String) -> void:
	dialogue_title = new_value
	update_configuration_warnings()


#endregion


func start() -> void:
	if not GameState.scene.intro_dialogue_shown:
		DialogueManager.show_dialogue_balloon(dialogue, dialogue_title, [self])
		await DialogueManager.dialogue_ended
		GameState.scene.intro_dialogue_shown = true

	cinematic_finished.emit()
	switch()
