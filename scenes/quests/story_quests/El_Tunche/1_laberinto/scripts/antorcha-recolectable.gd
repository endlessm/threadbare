extends Area2D
func _on_body_entered(body):
	if body.is_in_group("player"): 
		
		# 1. ENCONTRAR el gestor usando el Grupo GameManager
		var managers = get_tree().get_nodes_in_group("GameManager")
		
		if managers.size() > 0:
			var game_manager = managers[0]
			
			# 2. LLAMAR a la función si el gestor fue encontrado
			if game_manager.has_method("collect_torch"):
				game_manager.collect_torch()
		
		# 3. Eliminar la antorcha
		if $PointLight2D:
			$PointLight2D.enabled = false
			
		queue_free()
