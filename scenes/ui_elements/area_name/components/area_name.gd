# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

const MAX_LINEAS: int = 3
const MAX_CARACTERES_POR_LINEA: int = 10

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

var _zone_name: String = ""
var is_area = null 
var entered: bool = false

func _ready() -> void:
	# Consultamos el estado real una vez cargadas las variables
	is_area = GameState.global.is_area_unlocked(_zone_name)


func detect_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		entered = true


func detect_active_entered(body: Node2D) -> void:
	is_area = GameState.global.is_area_unlocked(_zone_name)
	if body.is_in_group("player") and entered:
		# Si is_area es null, significa que ya hay una animación ejecutándose. Bloqueamos.
		if is_area == null:
			return 

		entered = false 
		
		if is_area == false:
			is_area = null 
			
			var temp: Control = preload("res://scenes/ui_elements/area_name/first_unlock.tscn").instantiate()
			$CanvasLayer.add_child(temp)
			
			# Desbloqueamos en el GameState global
			GameState.global.set_unlock_area(_zone_name)
			GameState.save()
			
			await temp.animate_first_unlock(zone_name, time)
			temp.queue_free()
			
			$Timer.start()

		elif is_area == true:
			is_area = null # Bloqueamos ejecuciones simultáneas
			await %HUD.show_re_entry_zone(zone_name, time)
			$Timer.start() # Reinicia el temporizador para habilitar la siguiente reentrada


func _on_timer_timeout() -> void:
	is_area = true
