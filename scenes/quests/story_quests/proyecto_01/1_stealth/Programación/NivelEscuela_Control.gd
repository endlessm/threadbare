# NivelEscuela_Control.gd
extends Node2D

@export var llaves_necesarias: int = 3
var llaves_recolectadas: int = 0

@export var puerta_path: NodePath   # <- arrastras aquí tu nodo puerta en el Inspector
@onready var puerta: Node = get_node_or_null(puerta_path)

func _ready() -> void:
	print("Control del nivel listo. Llaves necesarias:", llaves_necesarias)
	if puerta == null:
		push_error("No se encontró la puerta. Asigna 'puerta_path' en el Inspector.")

func ActualizarLlaves() -> void:
	llaves_recolectadas += 1
	print("Llaves:", llaves_recolectadas, "/", llaves_necesarias)
	if llaves_recolectadas >= llaves_necesarias:
		AbrirPuerta()

func AbrirPuerta() -> void:
	if puerta and puerta.has_method("AbrirPuerta"):
		puerta.AbrirPuerta()
	elif puerta:
		# Fallback por si la puerta no tiene script
		var col = puerta.get_node_or_null("CollisionShape2D")
		var spr = puerta.get_node_or_null("Sprite2D")
		if col: col.disabled = true
		if spr: spr.visible = false
		print("✅ Puerta abierta (fallback).")
