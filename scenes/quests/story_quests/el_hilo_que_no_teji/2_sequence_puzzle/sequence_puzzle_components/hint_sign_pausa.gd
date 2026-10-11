# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends SequencePuzzleHintSign
## Como el letrero base, pero pausa el juego mientras muestra la secuencia.

const PAUSA_ENTRE_NOTAS: float = 0.45


func _on_interact_area_interaction_started(_player: Player, _from_right: bool) -> void:
	if sprite_frames.has_animation(&"hint"):
		animated_sprite.play(&"hint")

	var paso := _mi_paso()
	if interact_demonstrates and paso:
		get_tree().paused = true
		_demostrar_despacio(paso)
	else:
		demonstration_finished()


func _demostrar_despacio(paso: SequencePuzzleStep) -> void:
	for roca in paso.sequence:
		await roca.play()
		# El segundo argumento (true) hace que el timer siga corriendo aunque el juego esté en pausa
		await get_tree().create_timer(PAUSA_ENTRE_NOTAS, true).timeout
	demonstration_finished()


func _mi_paso() -> SequencePuzzleStep:
	var puzzle := get_parent().get_parent() as SequencePuzzle
	if not puzzle:
		return null
	for paso in puzzle.steps:
		if paso.hint_sign == self and not paso.is_solved:
			return paso
	return null


func demonstration_finished() -> void:
	if animated_sprite.animation == &"hint":
		if animated_sprite.is_playing():
			await animated_sprite.animation_finished
		animated_sprite.play(&"solved" if is_solved else &"idle")

	interact_area.end_interaction()
	get_tree().paused = false
