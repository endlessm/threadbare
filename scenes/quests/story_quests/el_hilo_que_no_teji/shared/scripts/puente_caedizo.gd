# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends TileMapLayer
## Puente de tablones que caen poco después de que Lino los pisa.

const DURACION_CAIDA_LINO: float = 0.9
const GIRO_AL_CAER: float = PI * 4

@export var tiempo_caida: float = 0.7
@export var jugador: Node2D
@export var ajuste_pies_y: float = 16.0

@export var tiempo_respiro_post_cinematica: float = 1.25
@export var nombres_capas_suelo: PackedStringArray = [
	"Suelo", "Grass", "GrassVerde", "Madera", "SubMadera", "GrassBossGris", "GrassBossBlanco"
]

var celdas_originales: Array[Vector2i] = []
var celdas_cayendo: Dictionary = {}
var lino_cayendo: bool = false

var estaba_en_cinematica: bool = false
var tiempo_respiro_restante: float = 0.0
var capas_suelo: Array[TileMapLayer] = []


func _ready() -> void:
	celdas_originales = get_used_cells()
	for nombre in nombres_capas_suelo:
		var capa := get_parent().get_node_or_null(NodePath(nombre)) as TileMapLayer
		if capa and capa != self:
			capas_suelo.append(capa)


func _physics_process(delta: float) -> void:
	if not visible or not jugador or lino_cayendo:
		return
	# Si el vacío ya lo atrapó, el juego lo reinicia solo: una segunda muerte repetiría la recarga.
	if jugador.mode == Player.Mode.DEFEATED:
		return
	if _esta_en_pausa_por_cinematica(delta):
		return
	_vigilar_los_pies_de_lino()
	_hacer_caer_los_tablones(delta)


func _esta_en_pausa_por_cinematica(delta: float) -> bool:
	if jugador.mode == jugador.Mode.SYSTEM_CONTROLLED:
		estaba_en_cinematica = true
		return true
	if estaba_en_cinematica:
		estaba_en_cinematica = false
		tiempo_respiro_restante = maxf(tiempo_respiro_restante, tiempo_respiro_post_cinematica)
	if tiempo_respiro_restante > 0.0:
		tiempo_respiro_restante -= delta
		return true
	return false


func _vigilar_los_pies_de_lino() -> void:
	var posicion_pies := jugador.global_position + Vector2(0, ajuste_pies_y)
	var posicion_celda := local_to_map(to_local(posicion_pies))
	if posicion_celda not in celdas_originales:
		return
	if get_cell_source_id(posicion_celda) != -1:
		if not celdas_cayendo.has(posicion_celda):
			celdas_cayendo[posicion_celda] = tiempo_caida
	elif not _hay_suelo_en(posicion_pies):
		_matar_a_lino()


func _hacer_caer_los_tablones(delta: float) -> void:
	var celdas_a_borrar: Array[Vector2i] = []
	for celda: Vector2i in celdas_cayendo.keys():
		celdas_cayendo[celda] -= delta
		if celdas_cayendo[celda] <= 0.0:
			set_cell(celda, -1)
			celdas_a_borrar.append(celda)
	for celda in celdas_a_borrar:
		celdas_cayendo.erase(celda)


func _hay_suelo_en(posicion_global: Vector2) -> bool:
	for capa in capas_suelo:
		var celda := capa.local_to_map(capa.to_local(posicion_global))
		if capa.get_cell_source_id(celda) != -1:
			return true
	return false


func _matar_a_lino() -> void:
	lino_cayendo = true

	if jugador.has_method("take_control"):
		jugador.take_control(self)

	jugador.velocity = Vector2.ZERO
	# Mientras cae, nada más puede atraparlo: si no, moriría varias veces.
	if jugador is CollisionObject2D:
		jugador.set_deferred("collision_layer", 0)

	await _hundir_a_lino()
	# Si el vacío atrapó a Lino mientras caía, esa muerte ya se encarga de recargar el nivel.
	if jugador.mode == Player.Mode.DEFEATED:
		return
	_perder_una_vida()


func _hundir_a_lino() -> void:
	var animacion_caida := create_tween()
	animacion_caida.tween_property(jugador, "scale", Vector2.ZERO, DURACION_CAIDA_LINO).set_trans(
		Tween.TRANS_SINE
	)
	animacion_caida.tween_property(jugador, "rotation", GIRO_AL_CAER, DURACION_CAIDA_LINO)
	await animacion_caida.finished


func _perder_una_vida() -> void:
	var estado_jugador: PlayerState = GameState.player
	if estado_jugador:
		estado_jugador.decrement_lives()

	if not estado_jugador or estado_jugador.lives > 0:
		var ruta_actual := get_tree().current_scene.scene_file_path
		SceneSwitcher.change_to_file_with_transition(ruta_actual)
	elif jugador.has_method("_handle_game_over"):
		jugador._handle_game_over()
