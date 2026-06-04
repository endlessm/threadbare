extends CanvasLayer

@onready var panel = $Panel 
@onready var label = $Panel/Label 

func mostrar_mensaje(texto):
	if label: 
		label.text = texto
		panel.show()
	else:
		push_error("¡El nodo Label no está donde dice el script! Revisa la ruta.")
