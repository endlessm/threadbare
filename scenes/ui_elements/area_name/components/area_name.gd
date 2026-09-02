# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

const MAX_LINEAS: int = 3
const MAX_CARACTERES_POR_LINEA: int = 10

var _zone_name: String = ""
var use: int = -1
var entered: bool = false

@export_multiline var zone_name: String:
	set(valor):
		var lineas: PackedStringArray = valor.split("\n")
		
		if lineas.size() > MAX_LINEAS:
			lineas = lineas.slice(0, MAX_LINEAS)
		
		for i in range(lineas.size()):
			if lineas[i].length() > MAX_CARACTERES_POR_LINEA:
				lineas[i] = lineas[i].substr(0, MAX_CARACTERES_POR_LINEA)
		
		_zone_name = "\n".join(lineas)
	get:
		return _zone_name

@export_range(1, 3) var time: int = 2

func detect_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		entered = true


func detect_active_entered(body: Node2D) -> void:
	if body.is_in_group("player") and entered:
		entered = false # Se desmarca inmediatamente para evitar reentradas continuas en este frame
		
		if use == -1:
			use = 0 # Bloqueamos ejecuciones simultáneas
			var temp: Control = preload("res://scenes/ui_elements/area_name/first_unlock.tscn").instantiate()
			$CanvasLayer.add_child(temp)
			await temp.animate_first_unlock(zone_name, time)
			temp.queue_free()
			$Timer.start() # Inicia el temporizador para habilitar el re-entry (pasa use a 1)

		elif use == 1:
			use = 0 # Bloqueamos ejecuciones simultáneas
			await %HUD.show_re_entry_zone(zone_name, time)
			$Timer.start() # Reinicia el temporizador para habilitar la siguiente reentrada


func _on_timer_timeout() -> void:
	use = 1