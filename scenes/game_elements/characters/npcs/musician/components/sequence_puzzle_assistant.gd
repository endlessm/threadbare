# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
## An NPC who can assist the player with a sequence puzzle.
##
## If the [member NPC.sprite_frames] has a [code]solved[/code] animation, this will be played
## continuously once [member puzzle] is solved.
@tool
class_name SequencePuzzleAssistant
extends Talker

## The puzzle that this NPC can help the player with. The [member Talker.dialogue] configured on
## this node can refer to this property as [code]puzzle[/code].
@export var puzzle: SequencePuzzle:
	set(new_value):
		puzzle = new_value
		update_configuration_warnings()

## The [member Talker.dialogue] configured on this node can check and modify this property to play
## different dialogue for the player's first interaction with this NPC, if desired.
var first_conversation: bool = true


func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		return

	puzzle.solved.connect(_on_puzzle_solved)


## Call this method from dialogue to record that the player has been offered one more hint for the
## current step of the [member puzzle].
func advance_hint_level() -> void:
	var progress := puzzle.get_progress()
	puzzle.hint_levels[progress] = puzzle.hint_levels.get(progress, 0) + 1


## Call this method from dialogue to check the number of hints that have been given to the player
## for the current step of the [member puzzle].
func get_hint_level() -> int:
	var progress: int = puzzle.get_progress()
	return puzzle.hint_levels.get(progress, 0)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray

	if not puzzle:
		warnings.append("No puzzle assigned")

	return warnings


func _on_puzzle_solved() -> void:
	if sprite_frames.has_animation(&"solved"):
		animated_sprite_2d.play(&"solved")
