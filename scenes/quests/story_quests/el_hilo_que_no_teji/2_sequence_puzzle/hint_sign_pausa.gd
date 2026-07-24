extends SequencePuzzleHintSign

# Al heredar (extends) del script original, Godot lo acepta como válido.
# Solo necesitamos "sobreescribir" las dos funciones donde queremos inyectar la pausa.

func _on_interact_area_interaction_started(_player: Player, _from_right: bool) -> void:
	if sprite_frames.has_animation(&"hint"):
		animated_sprite.play(&"hint")

	if interact_demonstrates and demonstrate_sequence.has_connections():
		# ---> MAGIA: PAUSAMOS EL JUEGO AL INICIAR LA DEMOSTRACIÓN <---
		get_tree().paused = true 
		demonstrate_sequence.emit()
	else:
		demonstration_finished()


func demonstration_finished() -> void:
	if animated_sprite.animation == &"hint":
		if animated_sprite.is_playing():
			await animated_sprite.animation_finished

		animated_sprite.play(&"solved" if is_solved else &"idle")

	interact_area.end_interaction()
	# ---> MAGIA: QUITAMOS LA PAUSA AL TERMINAR <---
	get_tree().paused = false
