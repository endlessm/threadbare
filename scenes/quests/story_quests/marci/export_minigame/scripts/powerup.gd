extends Area2D

@export var type := "rate"

@onready var sprite: Sprite2D = $Sprite2D
@onready var texture_rate := preload("res://scenes/quests/story_quests/marci/export_minigame/assets/powerup_gold.png")
@onready var texture_bomb := preload("res://scenes/quests/story_quests/marci/export_minigame/assets/powerup_red.png")

func _ready():
	add_to_group("powerups")
	connect("body_entered", Callable(self, "_on_body_entered"))
	_update_sprite()

func _update_sprite():
	match type:
		"rate":
			sprite.texture = texture_rate
		"bomb":
			sprite.texture = texture_bomb

func _on_body_entered(body):
	if not body.is_in_group("player"):
		return

	if type == "rate":
		body.shoot_delay = max(0.1, body.shoot_delay - 0.1)
	elif type == "bomb":
		get_tree().get_first_node_in_group("main").clear_enemies()

	queue_free()
