extends Area2D

@export_file("*.tscn") var escena_destino: String
var jugador_en_rango: bool = false
@onready var mensaje_label: Label = $Label

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if mensaje_label:
		mensaje_label.hide()

func _process(_delta: float) -> void:
	if jugador_en_rango and Input.is_key_pressed(KEY_Q):
		cambiar_de_nivel()

func cambiar_de_nivel() -> void:
	if escena_destino == "":
		print("❌ ERROR: No has asignado una escena destino a esta puerta.")
		return
	print("🚪 Entrando a: ", escena_destino)
	if DatosGlobales:
		DatosGlobales.current_health = DatosGlobales.max_health
	get_tree().change_scene_to_file(escena_destino)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		jugador_en_rango = true
		if mensaje_label:
			mensaje_label.show()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		jugador_en_rango = false
		if mensaje_label:
			mensaje_label.hide()
