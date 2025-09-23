# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Talker
signal dialogo_terminado


# Esta función la llamará el .dialogue al terminar
func avisar_que_el_dialogo_termino() -> void:
	print("[ArbolFantasma1:", name, "] Diálogo terminó -> emitiendo señal.")
	dialogo_terminado.emit()
