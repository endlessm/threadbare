extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	print("Ritual listo, grupos: ", get_groups())

func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	print("Jugador tocó un ritual")
	_check_all_collected()
	queue_free()

func _check_all_collected() -> void:
	var remaining := get_tree().get_nodes_in_group("ritual_object")
	remaining.erase(self)
	print("Rituales restantes (sin contar este): ", remaining.size())
	if remaining.is_empty():
		var finals := get_tree().get_nodes_in_group("final_collectible")
		print("Items finales encontrados: ", finals.size())
		for f in finals:
			if f.has_method("reveal"):
				print("Llamando reveal() en: ", f.name)
				f.reveal()
