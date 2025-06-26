extends Node2D

@onready var secondary_hud = $SecondaryHUD
@onready var obstacle = $TileMapLayers/StaticBody2D

func _ready():
	if secondary_hud.has_signal("all_items_collected"):
		secondary_hud.all_items_collected.connect(_on_all_items_collected)

func _on_all_items_collected():
	print("✅ Todos los objetos recolectados. Eliminando obstáculo.")
	obstacle.queue_free()  # También puedes usar: obstacle.set_deferred("disabled", true)
