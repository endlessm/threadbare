extends Area2D

@export var letra: String = "A"
@export var indice_en_palabra: int = 0

# ── Zona jugable de la sala (ajusta estos valores en el Inspector) ──
@export var sala_min: Vector2 = Vector2(-280, -96)
@export var sala_max: Vector2 = Vector2(1880, 1000)

var recogida: bool = false

@onready var label: Label = $Label

signal letra_iluminada(letra: String, indice: int)
signal letra_oscurecida(letra: String, indice: int)

func _ready() -> void:
	add_to_group("hidden_letter")
	if label:
		label.modulate.a = 0.0
		label.text = letra
	_posicionarse_aleatorio()

func _posicionarse_aleatorio() -> void:
	var pos = Vector2(
		randf_range(sala_min.x, sala_max.x),
		randf_range(sala_min.y, sala_max.y)
	)
	position = pos

func revelar_desde_player() -> void:
	if recogida:
		return
	_revelar()
	letra_iluminada.emit(letra, indice_en_palabra)

func oscurecer_desde_player() -> void:
	if recogida:
		return
	_oscurecer()
	letra_oscurecida.emit(letra, indice_en_palabra)

func _revelar() -> void:
	if label:
		var tween := create_tween()
		tween.tween_property(label, "modulate:a", 1.0, 0.25)

func _oscurecer() -> void:
	if label:
		var tween := create_tween()
		tween.tween_property(label, "modulate:a", 0.0, 0.4)

func marcar_recogida() -> void:
	recogida = true
	if label:
		label.modulate = Color(0.4, 1.0, 0.4)
