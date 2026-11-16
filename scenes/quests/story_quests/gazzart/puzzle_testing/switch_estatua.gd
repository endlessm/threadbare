# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

signal estado_cambiado(presionado: bool)

@export var desplazamiento_presionado: Vector2 = Vector2(0, 4)
@export var color_presionado: Color = Color(0.85, 0.85, 0.95, 1.0)
@export var color_sin_presionar: Color = Color(1, 1, 1, 1)
@export_node_path("Sprite2D") var sprite_path: NodePath
@export_node_path("Area2D") var area_path: NodePath
@export var objetivos: Array[SwitchEstatuaObjetivo] = []

var _jugadores_sobre_switch: int = 0
var _esta_presionado: bool = false

var sprite: Sprite2D = null
var area: Area2D = null
var _posicion_base_sprite: Vector2 = Vector2.ZERO

func _ready() -> void:
	sprite = _obtener_nodo(sprite_path, "Sprite2D") as Sprite2D
	area = _obtener_nodo(area_path, "Area2D") as Area2D

	if not sprite:
		push_warning("Switch sin Sprite2D: ", name)
	else:
		_posicion_base_sprite = sprite.position
	if area:
		area.body_entered.connect(_on_area_body_entered)
		area.body_exited.connect(_on_area_body_exited)
	_actualizar_estado()

func _on_area_body_entered(body: Node2D) -> void:
	if body and body.is_in_group("player"):
		_jugadores_sobre_switch += 1
		_actualizar_presionado(true)

func _on_area_body_exited(body: Node2D) -> void:
	if body and body.is_in_group("player"):
		_jugadores_sobre_switch = max(0, _jugadores_sobre_switch - 1)
		if _jugadores_sobre_switch == 0:
			_actualizar_presionado(false)

func _actualizar_presionado(nuevo_estado: bool) -> void:
	if _esta_presionado == nuevo_estado:
		return
	_esta_presionado = nuevo_estado
	_actualizar_estado()
	estado_cambiado.emit(_esta_presionado)
	if _esta_presionado:
		_aplicar_objetivos()

func _actualizar_estado() -> void:
	if sprite:
		sprite.position = _posicion_base_sprite + (desplazamiento_presionado if _esta_presionado else Vector2.ZERO)
		sprite.modulate = color_presionado if _esta_presionado else color_sin_presionar

func esta_presionado() -> bool:
	return _esta_presionado

func _obtener_nodo(path: NodePath, fallback_name: String) -> Node:
	if path != NodePath(""):
		return get_node_or_null(path)
	return get_node_or_null(fallback_name)


func _aplicar_objetivos() -> void:
	for objetivo in objetivos:
		if not objetivo:
			continue
		var estatua := get_node_or_null(objetivo.estatua_path)
		if estatua and estatua.has_method("mirar_por_nombre"):
			estatua.call_deferred("mirar_por_nombre", objetivo.direccion)
