# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Talker
signal dialogo_terminado2


# Esta función la llamará el .dialogue al terminar
func avisar_que_el_dialogo_termino2() -> void:
	print("[ArbolFantasma2:", name, "] Diálogo terminó -> emitiendo señal.")
	dialogo_terminado2.emit()
