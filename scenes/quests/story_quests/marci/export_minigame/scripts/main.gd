extends Node2D

@onready var player := $Player
@onready var score_label = $CanvasLayer/LabelScore
@onready var hp_label = $CanvasLayer/LabelHP
@onready var spawner := $EnemySpawner

var score := 0
var kills := 0

func _ready():
	add_to_group("main")
	spawner.timeout.connect(spawn_enemy)
	spawner.start()
	update_hud()

func spawn_enemy():
	var enemy = load("res://scenes/quests/story_quests/marci/export_minigame/scenes/enemy.tscn").instantiate()
	enemy.position = Vector2(randi_range(0, 900), randi_range(0, 600))
	add_child(enemy)
	enemy.add_to_group("enemies")

func enemy_killed():
	score += 1
	kills += 1
	update_hud()

	if kills % 8 == 0:
		spawn_powerup("rate")
	if kills % 15 == 0 and randf() < 0.7:
		spawn_powerup("bomb")

func spawn_powerup(t):
	var p = load("res://scenes/quests/story_quests/marci/export_minigame/scenes/powerup.tscn").instantiate()
	p.position = Vector2(randi_range(0, 900), randi_range(0, 600))
	p.type = t
	add_child(p)

func clear_enemies():
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()

func update_hud():
	if score_label:
		score_label.text = "Puntuación: %s" % score
	if hp_label and player:
		hp_label.text = "HP: %s" % player.hp
