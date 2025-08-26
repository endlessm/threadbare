# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
## An NPC who can assist the player with a sequence puzzle.
@tool
class_name SequencePuzzleAssistant2
extends Talker


signal abrir_camino
## The puzzle that this NPC can help the player with. The [member Talker.dialogue] configured on
## this node can refer to this property as [code]puzzle[/code].
@export var abre_camino: bool = false

@export var puzzle: SequencePuzzle:
	
	set(new_value):
		puzzle = new_value
		update_configuration_warnings()

## The [member Talker.dialogue] configured on this node can check and modify this property to play
## different dialogue for the player's first interaction with this NPC, if desired.
var first_conversation: bool = true




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

func entregar_fragmento() -> void:
	print("Fragmento entregado correctamente!")
	emit_signal("abrir_camino")


func _on_abrir_camino() -> void:
	$TileMapLayer.abrir_camino()  # Asegúrate que el nodo se llama así
