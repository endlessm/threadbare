extends Node2D

@onready var secondary_hud = $ObjetosHUD/SecondaryHUD
@onready var obstacle = $TileMapLayers/StaticBody2D


func _ready():
	if secondary_hud.has_signal("all_items_collected"):
		secondary_hud.all_items_collected.connect(_on_all_items_collected)

func _on_all_items_collected():
	print("✅ Todos los objetos recolectados. Eliminando obstáculo.")
	var sound = AudioStreamPlayer.new()
	sound.stream = preload("res://assets/third_party/sounds/characters/npcs/HammerSound.ogg")  # Usa aquí la ruta a tu sonido
	add_child(sound)
	sound.play()
	obstacle.queue_free()  # También puedes usar: obstacle.set_deferred("disabled", true)
