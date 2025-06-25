extends Area2D

@onready var sprite: Sprite2D = $Sprite2D
var posicion_inicial: Vector2
var presionado: bool = false

func _ready() -> void:
	posicion_inicial = position

func presionar_temporal() -> void:
	if presionado:
		return
	presionado = true
	position = posicion_inicial - Vector2(0, 50)  # ⬆️ se mueve hacia arriba
	$AudioStreamPlayer2D.play()
	await get_tree().create_timer(0.15).timeout
	position = posicion_inicial
	presionado = false

func presionar_y_quedarse() -> void:
	position = posicion_inicial - Vector2(0, 50)
	$AudioStreamPlayer2D.play()  # ⬆️ se queda arriba
	presionado = true

func soltar()-> void:
	position = posicion_inicial
	presionado = false
