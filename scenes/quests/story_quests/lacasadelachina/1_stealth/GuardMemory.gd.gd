extends "res://scenes/game_elements/characters/enemies/guard/components/guard.gd"

var ya_activado: bool = false

@onready var minijuego = get_node("/root/LacasadelachinaStealth/ScreenOverlay/Memorygame")
@onready var zona = get_node("zonewar")

func _ready() -> void:
	super._ready()
	zona.body_entered.connect(_on_zona_body_entered)

func _on_zona_body_entered(body: Node2D):
	if ya_activado:
		return
	if body.is_in_group("player"):
		ya_activado = true
		minijuego.iniciar()

func _on_detection_area_body_entered(body: Node2D) -> void:
	pass

func _on_instant_detection_area_body_entered(body: Node2D) -> void:
	pass
