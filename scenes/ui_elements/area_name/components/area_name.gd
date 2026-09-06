# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

# Definimos las opciones que aparecerán en el Inspector
enum Direcciones {
	UP = 1,
	DOWN = 2,
	LEFT = 4,
	RIGHT = 8,
	UP_LEFT = 16,
	UP_RIGHT = 32,
	DOWN_LEFT = 64,
	DOWN_RIGHT = 128
}

# Diccionario interno que traduce el nombre a un Vector2 real
const VECTORES_DIRECCION = {
	Direcciones.UP: Vector2.UP,
	Direcciones.DOWN: Vector2.DOWN,
	Direcciones.LEFT: Vector2.LEFT,
	Direcciones.RIGHT: Vector2.RIGHT,
	Direcciones.UP_LEFT: Vector2(-0.707, -0.707),
	Direcciones.UP_RIGHT: Vector2(0.707, -0.707),
	Direcciones.DOWN_LEFT: Vector2(-0.707, 0.707),
	Direcciones.DOWN_RIGHT: Vector2(0.707, 0.707)
}

const MAX_LINEAS: int = 3
const MAX_CARACTERES_POR_LINEA: int = 10

@export_flags("UP", "DOWN", "LEFT", "RIGHT", "UP_LEFT", "UP_RIGHT", "DOWN_LEFT", "DOWN_RIGHT") var direcciones_salida: int = 4

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
var tolerancia_grados: float = 60.0

func _ready() -> void:
	is_area = GameState.global.is_area_unlocked(_zone_name)


func _on_detect_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	
	var dir_jugador: Vector2 = Vector2.ZERO
	
	if "velocity" in body and body.velocity != Vector2.ZERO:
		dir_jugador = body.velocity.normalized()
	else:
		dir_jugador = (body.global_position - global_position).normalized()
	
	var es_salida_valida: bool = false
	
	# Recorremos cada dirección seleccionada en los flags
	for flag in VECTORES_DIRECCION.keys():
		if direcciones_salida & flag:
			var dir_permitida: Vector2 = VECTORES_DIRECCION[flag]
			var angulo_diferencia: float = rad_to_deg(dir_jugador.angle_to(dir_permitida))
			if abs(angulo_diferencia) <= tolerancia_grados:
				es_salida_valida = true
				break
	
	if es_salida_valida:
		_ejecutar_transicion()


func _ejecutar_transicion() -> void:
	is_area = GameState.global.is_area_unlocked(_zone_name)
	
	if is_area == null:
		return 
		
	if is_area == false:
		is_area = null 
		
		var temp: Control = preload("res://scenes/ui_elements/area_name/first_unlock.tscn").instantiate()
		$CanvasLayer.add_child(temp)
		
		GameState.global.set_unlock_area(_zone_name)
		GameState.save()
		
		await temp.animate_first_unlock(zone_name, time)
		temp.queue_free()
		
		$Timer.start()

	elif is_area == true:
		is_area = null
		await %HUD.show_re_entry_zone(zone_name, time)
		$Timer.start()


func _on_timer_timeout() -> void:
	is_area = true
