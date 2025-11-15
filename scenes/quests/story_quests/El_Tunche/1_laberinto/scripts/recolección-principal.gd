extends Node2D

var torches_collected = 0

# ¡AJUSTA ESTA RUTA! Debe apuntar exactamente a tu nodo Label de la UI.
# Ejemplo: $CanvasLayer/HBoxContainer/Label
@onready var torch_label = $CanvasLayer/HBoxContainer/Label 

func _ready():
	# Inicializa el contador de la UI
	update_torch_ui()

# ESTA ES LA FUNCIÓN CLAVE que la antorcha llama para actualizar el contador.
func collect_torch():
	# Línea de prueba para verificar la comunicación
	print("¡Antorcha recolectada! El gestor recibió la llamada.") 
	
	torches_collected += 1
	# Llama a la función que cambia el texto del Label
	update_torch_ui()
	
func update_torch_ui():
	# Actualiza el texto en el Label
	if is_instance_valid(torch_label):
		torch_label.text = "x" + str(torches_collected)
