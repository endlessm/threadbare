# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

## Señal emitida cuando el bloque aparece (colisión activa)
signal bloque_mostrado
## Señal emitida cuando el bloque desaparece (colisión desactivada)
signal bloque_ocultado

## Si es true, el bloque está presente (visible y con colisión)
## Si es false, el bloque desaparece (sin colisión)
@export var activo: bool = true
@export var valor_objetivo: int = 0

var static_body: StaticBody2D = null
var collision_shape: CollisionShape2D = null
var sprite: Node2D = null

func _ready() -> void:
	static_body = get_node_or_null("StaticBody2D")
	if not static_body:
		push_warning("No se encontró StaticBody2D en el puente ", name)
	
	if static_body:
		collision_shape = static_body.get_node_or_null("CollisionShape2D")
		if not collision_shape:
			push_warning("No se encontró CollisionShape2D en el puente ", name)
	
	# Intentar obtener el sprite principal (opcional)
	sprite = get_node_or_null("Sprite2D")
	if not sprite:
		# Si el sprite está en un hijo distinto, tomar el primero que exista
		for child in get_children():
			if child is Sprite2D:
				sprite = child
				break

	_aplicar_estado()


## Activa el bloque (aparece y bloquea el paso)
func activar() -> void:
	if activo:
		return
	activo = true
	_aplicar_estado()
	bloque_mostrado.emit()


## Desactiva el bloque (desaparece y deja pasar)
func desactivar() -> void:
	if not activo:
		return
	activo = false
	_aplicar_estado()
	bloque_ocultado.emit()


## Alterna el estado del bloque
func alternar() -> void:
	if activo:
		desactivar()
	else:
		activar()


func _aplicar_estado() -> void:
	var colision_activa := activo
	if collision_shape:
		collision_shape.disabled = not colision_activa
	
	visible = activo
	if sprite:
		sprite.visible = activo


func obtener_valor() -> int:
	return valor_objetivo

