extends Node

func _ready():
	print("GameHooks listo")
	GameState.collected_items_changed.connect(_on_collected_items_changed)

func _on_collected_items_changed(items: Array) -> void:
	for item in items:
		if item is CustomInventoryItem:
			if item.target_hud == "SecondaryHUD":
				var hud = get_tree().get_current_scene().find_child("SecondaryHUD", true, false)
				if hud:
					hud.add_item(item)
			elif item.target_hud == "HUD":
				var hud = get_tree().get_current_scene().find_child("MainHUD", true, false)
				if hud:
					hud.add_item(item)
