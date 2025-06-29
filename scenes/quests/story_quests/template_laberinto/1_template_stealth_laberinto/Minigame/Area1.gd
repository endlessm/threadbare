extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("is_player") or body.name == "Player":
		get_tree().change_scene_to_file("res://scenes/quests/story_quests/template_laberinto/1_template_stealth_laberinto/Minigame/flow_free.tscn")
