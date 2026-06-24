extends Node2D

@onready var puerta: Area2D = $OnTheGround/puerta

func _ready() -> void:
	# Al iniciar el nivel, la puerta es invisible
	puerta.hide()
	
	# Apagamos sus sensores
	puerta.set_deferred("monitoring", false)
	puerta.set_deferred("monitorable", false)

# Esta función para revelar la salida
func mostrar_puerta() -> void:
	puerta.show()
	puerta.set_deferred("monitoring", true)
	puerta.set_deferred("monitorable", true)
	
	puerta.modulate = Color(1, 1, 1, 0) # 0% opacidad
	var tween: Tween = create_tween()
	tween.tween_property(puerta, "modulate", Color(1, 1, 1, 1), 1.5) 
