# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

## Señal emitida cuando el puzzle se completa
signal puzzle_completado

## Tolerancia para considerar que una caja está sobre un target (en píxeles)
@export var tolerancia_target: float = 32.0

var box1: RigidBody2D = null
var box2: RigidBody2D = null
var target1: Node2D = null
var target2: Node2D = null
var ya_gano: bool = false  # Para evitar múltiples mensajes de victoria

func _ready() -> void:
	# Obtener referencias a las cajas
	box1 = get_node_or_null("Boxes/Box1")
	box2 = get_node_or_null("Boxes/Box2")
	
	# Obtener referencias a los targets
	target1 = get_node_or_null("Target1")
	target2 = get_node_or_null("Target2")
	
	if not box1:
		print("Advertencia: No se encontró Box1")
	if not box2:
		print("Advertencia: No se encontró Box2")
	if not target1:
		print("Advertencia: No se encontró Target1")
	if not target2:
		print("Advertencia: No se encontró Target2")
	
	# Conectar las señales de movimiento de las cajas
	if box1:
		box1.caja_movida.connect(_verificar_victoria)
	if box2:
		box2.caja_movida.connect(_verificar_victoria)


func _verificar_victoria(_new_position: Vector2, _direccion: Vector2) -> void:
	# Esta función se llama cada vez que Box1 se mueve
	# Esperar un frame para que Box2 también se haya movido si corresponde
	call_deferred("_verificar_victoria_deferred")


func _verificar_victoria_deferred() -> void:
	if ya_gano:
		return
	
	if not box1 or not box2 or not target1 or not target2:
		return
	
	# Obtener las posiciones reales de las cajas (considerando CollisionShape2D)
	var posicion_box1 = _obtener_posicion_real_caja(box1)
	var posicion_box2 = _obtener_posicion_real_caja(box2)
	
	# Obtener las posiciones de los targets (usando el sprite si existe)
	var posicion_target1 = _obtener_posicion_target(target1)
	var posicion_target2 = _obtener_posicion_target(target2)
	
	# Verificar si Box1 está sobre Target1
	var box1_en_target1 = posicion_box1.distance_to(posicion_target1) <= tolerancia_target
	
	# Verificar si Box2 está sobre Target2
	var box2_en_target2 = posicion_box2.distance_to(posicion_target2) <= tolerancia_target
	
	# Si ambas cajas están en sus targets, ¡victoria!
	if box1_en_target1 and box2_en_target2:
		ya_gano = true
		print("¡VICTORIA! Ambas cajas están en sus targets.")
		puzzle_completado.emit()


func _obtener_posicion_real_caja(caja: RigidBody2D) -> Vector2:
	# Obtener la posición real de la caja (usando CollisionShape2D si existe)
	var posicion = caja.global_position
	var colision_caja = caja.get_node_or_null("CollisionShape2D")
	if colision_caja:
		# Calcular la posición global del CollisionShape2D
		posicion = caja.global_position + colision_caja.position
	return posicion


func _obtener_posicion_target(target: Node2D) -> Vector2:
	# Obtener la posición del target (usando el sprite si existe)
	var posicion = target.global_position
	var sprite = target.get_node_or_null("Target1Sprite")
	if not sprite:
		sprite = target.get_node_or_null("Target2Sprite")
	if sprite:
		# Calcular la posición global del sprite
		posicion = target.global_position + sprite.position
	return posicion
