# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name ClipSwitcher
extends Node
## Switch between clips in an [AudioStreamInteractive] on a [BackgroundMusic]
## node.
##
## This must be a child of a [BackgroundMusic] node, whose [member
## BackgroundMusic.stream] must be an [AudioStreamInteractive]. Either set
## [member trigger] to an Area2D in the scene, or call [method switch] in some
## other way.

## The name of the [AudioStreamInteractive] clip to switch to.
@export var clip: StringName:
	set = _set_clip

## Switch to [param clip] whenever this area emits [signal Area2D.body_entered].
## Typically the area should be configured to only detect the player, but you
## could imagine other possibilities.
@export var trigger: Area2D:
	set = _set_trigger

## If enabled, only [method switch] in response to [member trigger] emitting
## [signal Area2D.body_entered] once. If disabled, switch every time.
@export var one_shot: bool = true:
	set = _set_one_shot

var _bgm: BackgroundMusic


func _set_clip(value: StringName) -> void:
	clip = value
	update_configuration_warnings()


func _set_trigger(value: Area2D) -> void:
	if not Engine.is_editor_hint() and trigger:
		trigger.disconnect("body_entered", self._on_body_entered)
	trigger = value
	if not Engine.is_editor_hint() and trigger:
		var flags := ConnectFlags.CONNECT_ONE_SHOT if one_shot else 0
		trigger.connect("body_entered", self._on_body_entered, flags)


func _set_one_shot(value: bool) -> void:
	one_shot = value

	# reconnect signal
	_set_trigger(trigger)


func _validate_property(property: Dictionary) -> void:
	match property["name"]:
		"clip":
			if _bgm:
				property.type = TYPE_STRING
				property.hint = PROPERTY_HINT_ENUM
				property.hint_string = ",".join(_bgm._get_clip_names())
		"one_shot":
			if not trigger:
				property.usage |= PROPERTY_USAGE_READ_ONLY


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray
	if not _bgm:
		warnings.append("Must be a child of a BackgroundMusic node")
	else:
		var clip_names := _bgm._get_clip_names()
		if not clip_names:
			warnings.append(
				"BackgroundMusic stream has no clips - is it an AudioStreamInteractive?"
			)
		elif clip and clip not in clip_names:
			warnings.append("Clip '%s' doesn't exist on BackgroundMusic's stream" % clip)
	if not clip:
		warnings.append("Clip is not set")
	return warnings


func _enter_tree() -> void:
	_bgm = get_parent() as BackgroundMusic
	update_configuration_warnings()


func _exit_tree() -> void:
	_bgm = null


func _on_body_entered(_body: Node2D) -> void:
	switch()


## Tell the parent [BackgroundMusic] to switch to [member clip].
func switch() -> void:
	assert(_bgm)
	_bgm.switch_to_clip(clip)
