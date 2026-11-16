# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name PuzzleSumasController
extends Node2D

signal ronda_cambiada(indice_actual: int)
signal puzzle_sumas_completado

@export var botones_paths: Array[NodePath] = []
@export var rondas_paths: Array[NodePath] = []

class BotonData:
	var nodo
	var valor: int

class BloqueData:
	var nodo
	var valor: int

class RondaData:
	var nombre: String
	var bloques: Array[BloqueData] = []

var _botones: Array[BotonData] = []
var _rondas: Array[RondaData] = []
var _indice_ronda_actual: int = -1
var _indice_bloque_actual: int = 0
var _valor_restante_actual: int = 0
var _puzzle_terminado: bool = false


func _ready() -> void:
	_cargar_botones()
	_cargar_rondas()
	if _rondas.is_empty():
		_puzzle_terminado = true
		return
	_iniciar_ronda(0)


func _cargar_botones() -> void:
	for path in botones_paths:
		var nodo := get_node_or_null(path)
		if not nodo:
			push_warning("No se encontró el botón en la ruta: ", path)
			continue
		var data := BotonData.new()
		data.nodo = nodo
		data.valor = _obtener_valor_boton(nodo)
		if data.valor <= 0:
			push_warning("El botón %s tiene un valor no válido (%d)" % [nodo.name, data.valor])
		_botones.append(data)
		if nodo.has_signal("boton_presionado"):
			nodo.connect("boton_presionado", Callable(self, "_on_boton_presionado"))


func _obtener_valor_boton(nodo: Node) -> int:
	if _tiene_propiedad(nodo, "valor_boton"):
		return int(nodo.get("valor_boton"))
	if nodo.has_method("get_valor"):
		return int(nodo.call("get_valor"))
	return 0


func _cargar_rondas() -> void:
	for path in rondas_paths:
		var ronda_node := get_node_or_null(path)
		if not ronda_node:
			push_warning("No se encontró el nodo de PuenteSuma: ", path)
			continue
		var ronda := RondaData.new()
		ronda.nombre = ronda_node.name
		for child in ronda_node.get_children():
			if not child or not child.has_method("activar") or not _tiene_propiedad(child, "valor_objetivo"):
				continue
			var bloque := BloqueData.new()
			bloque.nodo = child
			bloque.valor = int(child.get("valor_objetivo"))
			if bloque.valor <= 0:
				push_warning("El bloque %s en %s tiene un valor no válido (%d)" % [child.name, ronda.nombre, bloque.valor])
			ronda.bloques.append(bloque)
		if ronda.bloques.is_empty():
			continue
		ronda.bloques.sort_custom(Callable(self, "_ordenar_bloques_por_y"))
		_rondas.append(ronda)


func _ordenar_bloques_por_y(a: BloqueData, b: BloqueData) -> bool:
	# Queremos procesar de abajo hacia arriba (mayor Y primero)
	return a.nodo.global_position.y > b.nodo.global_position.y


func _iniciar_ronda(indice: int) -> void:
	if indice >= _rondas.size():
		_puzzle_terminado = true
		puzzle_sumas_completado.emit()
		return
	_indice_ronda_actual = indice
	_indice_bloque_actual = 0
	var ronda := _rondas[indice]
	for bloque in ronda.bloques:
		if bloque.nodo.has_method("activar"):
			bloque.nodo.call("activar")
	_valor_restante_actual = ronda.bloques[0].valor
	_reiniciar_botones()
	ronda_cambiada.emit(indice)


func _on_boton_presionado(valor_boton: int) -> void:
	if _puzzle_terminado:
		return
	if _indice_ronda_actual < 0 or _indice_ronda_actual >= _rondas.size():
		return
	var ronda := _rondas[_indice_ronda_actual]
	if _indice_bloque_actual >= ronda.bloques.size():
		return

	_valor_restante_actual -= valor_boton

	if _valor_restante_actual == 0:
		_resolver_bloque_actual()
	elif _valor_restante_actual < 0:
		_reiniciar_ronda_actual()
	else:
		# Continúa el mismo bloque con los botones restantes
		pass


func _resolver_bloque_actual() -> void:
	var ronda := _rondas[_indice_ronda_actual]
	var bloque := ronda.bloques[_indice_bloque_actual]
	if bloque.nodo.has_method("desactivar"):
		bloque.nodo.call("desactivar")
	_indice_bloque_actual += 1

	if _indice_bloque_actual >= ronda.bloques.size():
		# Ronda completada
		_reiniciar_botones()
		_iniciar_ronda(_indice_ronda_actual + 1)
	else:
		_valor_restante_actual = ronda.bloques[_indice_bloque_actual].valor


func _reiniciar_ronda_actual() -> void:
	var ronda := _rondas[_indice_ronda_actual]
	for bloque in ronda.bloques:
		if bloque.nodo.has_method("activar"):
			bloque.nodo.call("activar")
	_indice_bloque_actual = 0
	_valor_restante_actual = ronda.bloques[0].valor
	_reiniciar_botones()


func _reiniciar_botones() -> void:
	for boton in _botones:
		if boton.nodo and boton.nodo.has_method("reiniciar_boton"):
			boton.nodo.call_deferred("reiniciar_boton")


func _tiene_propiedad(obj: Object, nombre: String) -> bool:
	if not obj:
		return false
	for prop in obj.get_property_list():
		if prop.name == nombre:
			return true
	return false
