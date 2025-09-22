extends Talker
signal dialogo_terminado3


# Esta función la llamará el .dialogue al terminar
func avisar_que_el_dialogo_termino3() -> void:
	print("[ArbolFantasma3:", name, "] Diálogo terminó -> emitiendo señal.")
	dialogo_terminado3.emit()
