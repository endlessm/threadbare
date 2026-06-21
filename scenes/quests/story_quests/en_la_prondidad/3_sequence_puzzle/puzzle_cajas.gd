extends Node2D

# Referencia al objeto de recompensa (El Dibujo Roto)
@onready var objeto_recompensa: Area2D = $"../QuestItem3"

var zonas_completadas: int = 0
const TOTAL_ZONAS: int = 3

func _ready() -> void:
	# Conectamos las señales de todas las zonas que estén dentro de este nodo
	for hijo in get_children():
		if hijo is ZonaPresion:
			hijo.caja_colocada.connect(_on_caja_colocada)
			hijo.caja_retirada.connect(_on_caja_retirada)

func _on_caja_colocada() -> void:
	zonas_completadas += 1
	print("Caja en posición. progreso: ", zonas_completadas, "/", TOTAL_ZONAS)
	_verificar_puzzle()

func _on_caja_retirada() -> void:
	zonas_completadas -= 1
	print("Caja retirada. progreso: ", zonas_completadas, "/", TOTAL_ZONAS)

func _verificar_puzzle() -> void:
	if zonas_completadas >= TOTAL_ZONAS:
		print("¡Puzzle de cajas resuelto al 100%!")
		if objeto_recompensa and objeto_recompensa.has_method("reveal"):
			objeto_recompensa.reveal() # Esto hace aparecer el QuestItem3
			
			# Desactivamos el script para que no se vuelva a ejecutar
			set_process(false)
