extends Node2D

# 1. Define la ruta de la escena a la que quieres cambiar
const MINIGAME_SCENE_PATH = "res://1_laberinto/laberinto_tunche.tscn"

# 2. Agrega la lógica de cambio de escena dentro de la función generada
func _on_animation_player_2_animation_finished(anim_name: StringName) -> void:
	# Reemplaza 'pass' con este código:
	print("Intro terminada. Cambiando a Laberinto...")
	
	# Obtiene el SceneTree (el árbol de escenas principal)
	var tree = get_tree() 
	
	# Cambia la escena actual a la nueva escena (el laberinto)
	var error = tree.change_scene_to_file(MINIGAME_SCENE_PATH)
	
	if error != OK:
		print("ERROR: No se pudo cambiar a la escena. Código de error:", error)
