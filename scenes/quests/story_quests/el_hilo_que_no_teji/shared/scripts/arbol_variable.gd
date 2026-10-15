# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name ArbolVariable
extends Node2D
## Árbol pequeño de El Hilo Que No Tejí con variaciones sutiles.
##
## Cada árbol cambia un poco de tamaño, posición, orientación y tono, pero
## siempre es el mismo árbol. La variación sale de la posición del árbol, así
## que un árbol se ve igual en cada partida y en cada reaparición de Lino.

## Tamaño mínimo y máximo (1.0 = el tamaño original).
@export var escala_minima: float = 0.92
@export var escala_maxima: float = 1.1
## Cuánto puede moverse como máximo, en píxeles, hacia cada lado.
@export var desvio_maximo: Vector2 = Vector2(4, 3)
## Cuánto puede oscurecerse como máximo (0 = nada, 0.1 = un 10 %).
@export_range(0.0, 0.3, 0.01) var oscurecer_maximo: float = 0.08
## Si es verdadero, algunos árboles se ven reflejados.
@export var puede_voltearse: bool = true
## Con una semilla distinta de 0 se fuerza una variación concreta.
@export var semilla_manual: int = 0

@onready var _variacion: Node2D = $Variacion


func _ready() -> void:
	_aplicar_variacion()


func _aplicar_variacion() -> void:
	var azar := RandomNumberGenerator.new()
	if semilla_manual != 0:
		azar.seed = semilla_manual
	else:
		# La posición manda: mismo sitio, mismo árbol.
		azar.seed = hash(Vector2i(global_position.round()))

	var escala := azar.randf_range(escala_minima, escala_maxima)
	var lado := -1.0 if (puede_voltearse and azar.randf() < 0.5) else 1.0
	var desvio := Vector2(
		azar.randf_range(-desvio_maximo.x, desvio_maximo.x),
		azar.randf_range(-desvio_maximo.y, desvio_maximo.y)
	)
	var oscuro := 1.0 - azar.randf_range(0.0, oscurecer_maximo)

	_variacion.scale = Vector2(escala * lado, escala)
	# El pie del tronco (32 px bajo el centro) se queda en el suelo.
	_variacion.position = desvio + Vector2(0, 32.0 * (1.0 - escala))
	_variacion.modulate = Color(oscuro, oscuro, oscuro, 1.0)
