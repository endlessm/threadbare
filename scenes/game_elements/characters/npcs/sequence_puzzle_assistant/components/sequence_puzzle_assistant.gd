# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0

## An NPC who can assist the player with a sequence puzzle.
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

## Señal para indicar que el jugador terminó de hablar con el NPC.
signal interaction_ended

## Lógica del puzzle
func advance_hint_level() -> void:
	var progress := puzzle.get_progress()
	puzzle.hint_levels[progress] = puzzle.hint_levels.get(progress, 0) + 1

func get_hint_level() -> int:
	var progress: int = puzzle.get_progress()
	return puzzle.hint_levels.get(progress, 0)

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray
	if not puzzle:
		warnings.append("No puzzle assigned")
	return warnings

## Sobreescribimos para emitir la señal cuando el diálogo termine
func _on_dialogue_ended(_dialogue_resource: DialogueResource) -> void:
	super._on_dialogue_ended(_dialogue_resource)
	print("🟡 [NPC] Señal de fin de interacción recibida. Emite 'interaction_ended'")
	interaction_ended.emit()
