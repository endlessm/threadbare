# level_1.gd (o el script de tu escena de juego)
extends Node2D # O el tipo de nodo raíz de tu nivel


	# Opcional: Pausar el juego mientras el diálogo está activo
	# get_tree().paused = true
	# Si pausas el juego aquí, recuerda DESPAUSARLO en la función end_dialogue()
	# de tu script dialog_manager.gd:
	# func end_dialogue():
	#     hide()
	#     current_dialog_data = []
	#     current_dialog_index = 0
	#     get_tree().paused = false # Despausa el juego
	#     # emit_signal("dialogue_finished")
