# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name EstatuaPuzzle
extends RigidBody2D

enum Direction {
	UP,
	RIGHT,
	DOWN,
	LEFT,
}

@export_node_path("Sprite2D") var sprite_path: NodePath

@export var textura_arriba: Texture2D
@export var textura_derecha: Texture2D
@export var textura_abajo: Texture2D
@export var textura_izquierda: Texture2D

@export var direccion_inicial: Direction = Direction.DOWN

var _sprite: Sprite2D = null
var _direccion_actual: Direction = Direction.DOWN

func _ready() -> void:
	freeze = true
	gravity_scale = 0
	_sprite = _obtener_sprite()
	_direccion_actual = direccion_inicial
	_aplicar_direccion()


func mirar(direccion: Direction) -> void:
	if _direccion_actual == direccion:
		return
	_direccion_actual = direccion
	_aplicar_direccion()


func mirar_por_nombre(nombre: String) -> void:
	var dir := _nombre_a_direccion(nombre)
	mirar(dir)


func obtener_direccion_actual() -> Direction:
	return _direccion_actual


func _aplicar_direccion() -> void:
	if not _sprite:
		return
	var textura := _obtener_textura(_direccion_actual)
	if textura:
		_sprite.texture = textura


func _obtener_textura(direction: Direction) -> Texture2D:
	match direction:
		Direction.UP:
			return textura_arriba
		Direction.RIGHT:
			return textura_derecha
		Direction.DOWN:
			return textura_abajo
		Direction.LEFT:
			return textura_izquierda
	return null


func _obtener_sprite() -> Sprite2D:
	if sprite_path != NodePath(""):
		return get_node_or_null(sprite_path) as Sprite2D
	# Intentar obtener el primer Sprite2D hijo
	for child in get_children():
		if child is Sprite2D:
			return child
		if child is Node:
			var sprite := child.get_node_or_null("Sprite2D")
			if sprite:
				return sprite as Sprite2D
	return null


func _nombre_a_direccion(nombre: String) -> Direction:
	var lower := nombre.to_lower()
	match lower:
		"up", "arriba":
			return Direction.UP
		"right", "derecha":
			return Direction.RIGHT
		"left", "izquierda":
			return Direction.LEFT
		_:
			return Direction.DOWN
