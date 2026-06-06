extends Node2D

@onready var guardian    = get_node("EnemyGuards/Guard1-GoingBackAndForth")
@onready var memory_game = get_node("ScreenOverlay/Memorygame")

var guardian_bloqueado := true

func _ready() -> void:
	memory_game.minijuego_completado.connect(_on_minijuego_completado)
	# Desactiva completamente al guardián al inicio
	guardian.set_process(false)
	guardian.set_physics_process(false)

func _on_zona_dialogo_body_entered(body: Node2D) -> void:
	if guardian_bloqueado and body.is_in_group("player"):
		memory_game.iniciar()

func _on_minijuego_completado() -> void:
	guardian_bloqueado = false
	guardian.visible = false
