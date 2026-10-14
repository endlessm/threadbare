# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D
## Lógica del nivel 2: puentes, puzzles y Luto.

const AyudasDeEscena = preload("../../shared/scripts/ayudas_de_escena.gd")
const LuzDeRoca = preload("../../shared/scripts/luz_de_roca.gd")
const CinematicaVacio = preload("cinematica_llegada_del_vacio.gd")
const IslaDevorada = preload("cinematica_isla_devorada.gd")
const ROCAS_APAGADAS: Shader = preload(
	"../../shared/shaders/el_hilo_que_no_teji_rocas_apagadas.gdshader"
)
const NUBES_DEL_VACIO: PackedScene = preload("vacio_particulas_grandes.tscn")

const RUTA_PUENTE: String = "TileMapLayers/Puente%d"
const RUTA_PUENTE_ROTO: String = "TileMapLayers/PuenteRoto%d"
const RUTA_PUZZLE: String = "OnTheGround/Puzzle_Isla%d"
const RUTA_LETRERO: String = "OnTheGround/Puzzle_Isla%d/Hints/SequencePuzzleHintSign%d"
const RUTA_COLECCIONABLE: String = "OnTheGround/CollectibleItem%d"
const RUTA_VACIO: String = "OnTheGround/VoidSpreadingEnemy"

const CANTIDAD_PUENTES: int = 3
const CAPA_PAREDES: int = 16

const ISLAS_LUTO: Array[Vector2] = [
	Vector2(97, 4832),  # Isla del primer hilo (abajo a la izquierda)
	Vector2(97, 2720),  # Isla del segundo hilo (arriba a la izquierda)
	Vector2(3041, 2720),  # Isla del tercer hilo (arriba a la derecha)
]
const DISTANCIA_PARA_IRSE: float = 750.0
const PAUSA_ENTRE_LADRIDOS := Vector2(60.0, 95.0)
const LADRIDO_TRAS_CAMBIAR_DE_ISLA := Vector2(4.0, 7.0)
const PRIMER_LADRIDO := Vector2(3.0, 5.0)
const LADRIDOS_AL_AVISAR: int = 1
const DURACION_DESVANECER: float = 0.6

const COLOR_HAZ_DE_LUZ := Color(0.72, 0.8, 1.0)

const TIEMPO_CAIDA_DE_LOS_PUENTES: float = 1.1
const RESPIRO_TRAS_TEJER: float = 1.5

const COLOR_HALO_FOGATA := Color(1.0, 0.8, 0.45)
const TAMANO_TEXTURA_HALO: int = 128
const POSICION_HALO_FOGATA := Vector2(0, -24)
const LATIDO_DURACION: float = 0.9
const LATIDO_OPACIDAD_ALTA: float = 0.75
const LATIDO_OPACIDAD_BAJA: float = 0.15
const LATIDO_ESCALA_ALTA: float = 1.5
const INTENTOS_DE_ORDEN_NUEVO: int = 20

# Estas tres son static para que se conserven cuando Lino cae y el nivel se recarga.
# ultimo_orden guarda el último orden sorteado para no repetirlo
static var puentes_listos: Array[bool] = [false, false, false]
static var ultimo_orden: Dictionary = {}
static var isla_de_luto: int = 0

## Se activa al descargar la escena: los hilos que siguen en ella emiten tree_exited y no cuentan.
var nivel_apagandose: bool = false
var luto_cambiando_de_isla: bool = false
var proximo_ladrido: float = 0.0
var posicion_final_luto: Vector2

@onready var luto: AnimatedSprite2D = $OnTheGround/Luto
@onready var jugador: Node2D = $OnTheGround/Player


func _ready() -> void:
	_cargar_progreso()

	GameState.player.set_ability(Enums.PlayerAbilities.ABILITY_B, false)
	nivel_apagandose = false
	tree_exiting.connect(_marcar_nivel_apagandose)

	_preparar_puentes()
	_barajar_puzzles()
	_encender_rocas_al_sonar()
	_marcar_fogatas()
	add_child(IslaDevorada.new())
	_pintar_haces_de_luz()
	_apagar_rocas()
	posicion_final_luto = luto.global_position
	luto.add_child(EfectoFantasma.new())
	_agregar_pesadilla()
	_poner_a_luto_en_su_isla()
	proximo_ladrido = _al_azar(PRIMER_LADRIDO)
	_esperar_a_que_lino_reaparezca()


func _process(delta: float) -> void:
	if not is_instance_valid(luto) or luto_cambiando_de_isla:
		return

	var lino_cerca := (
		jugador.global_position.distance_to(luto.global_position) < DISTANCIA_PARA_IRSE
	)
	if isla_de_luto < ISLAS_LUTO.size() and lino_cerca:
		_luto_se_va_a_la_siguiente_isla()
		return

	luto.flip_h = jugador.global_position.x < luto.global_position.x
	proximo_ladrido -= delta
	if proximo_ladrido <= 0.0:
		proximo_ladrido = _al_azar(PAUSA_ENTRE_LADRIDOS)
		_ladrar()


func _cargar_progreso() -> void:
	if ElHiloQueNoTejiState.es_partida_nueva_para("sequence_puzzle"):
		puentes_listos = [false, false, false]
		isla_de_luto = 0
		CinematicaVacio.vista = false
		IslaDevorada.hechas = [false, false]
		ultimo_orden.clear()
		return
	for indice in IslaDevorada.hechas.size():
		IslaDevorada.hechas[indice] = IslaDevorada.hechas[indice] and puentes_listos[indice + 1]


func _preparar_puentes() -> void:
	for numero in range(1, CANTIDAD_PUENTES + 1):
		var puente := _puente(numero)
		var puente_roto := _puente_roto(numero)
		if puente:
			puente.visible = not CinematicaVacio.vista
		if puente_roto and not CinematicaVacio.vista:
			puente_roto.enabled = false
		if puentes_listos[numero - 1]:
			_restaurar_puente_y_borrar_hilo(numero)

	for capa in $TileMapLayers.get_children():
		if "tiempo_caida" in capa:
			capa.tiempo_caida = TIEMPO_CAIDA_DE_LOS_PUENTES


func _agregar_pesadilla() -> void:
	var pesadilla := Pesadilla.new()
	var vacio := get_node_or_null(RUTA_VACIO) as Node2D
	if vacio:
		pesadilla.amenazas = [vacio]
		vacio.set("void_particles", NUBES_DEL_VACIO)
	add_child(pesadilla)


func _esperar_a_que_lino_reaparezca() -> void:
	var reaparicion := ReaparicionEnHilo.new()
	reaparicion.termino.connect(_ladrar_al_reaparecer)
	add_child(reaparicion)
	# su _ready se libera solo si no es una reaparición
	if not reaparicion.is_queued_for_deletion():
		proximo_ladrido = INF


func _puente(numero: int) -> TileMapLayer:
	return get_node_or_null(RUTA_PUENTE % numero) as TileMapLayer


func _puente_roto(numero: int) -> TileMapLayer:
	return get_node_or_null(RUTA_PUENTE_ROTO % numero) as TileMapLayer


func _letrero(numero: int) -> SequencePuzzleHintSign:
	return get_node_or_null(RUTA_LETRERO % [numero, numero]) as SequencePuzzleHintSign


func _al_azar(rango: Vector2) -> float:
	return randf_range(rango.x, rango.y)


func _ladrar() -> void:
	Ladrido.sonar(self, luto.global_position, LADRIDOS_AL_AVISAR)


func _ladrar_al_reaparecer() -> void:
	proximo_ladrido = _al_azar(PAUSA_ENTRE_LADRIDOS)
	if is_instance_valid(luto):
		_ladrar()


func _poner_a_luto_en_su_isla() -> void:
	if isla_de_luto < ISLAS_LUTO.size():
		luto.global_position = ISLAS_LUTO[isla_de_luto]
	else:
		luto.global_position = posicion_final_luto


func _luto_se_va_a_la_siguiente_isla() -> void:
	luto_cambiando_de_isla = true
	_ladrar()

	await _cambiar_opacidad_de_luto(0.0)

	isla_de_luto += 1
	_poner_a_luto_en_su_isla()

	await _cambiar_opacidad_de_luto(1.0)

	proximo_ladrido = _al_azar(LADRIDO_TRAS_CAMBIAR_DE_ISLA)
	luto_cambiando_de_isla = false


func _cambiar_opacidad_de_luto(opacidad: float) -> void:
	var cambio := create_tween()
	cambio.tween_property(luto, "modulate:a", opacidad, DURACION_DESVANECER)
	await cambio.finished


func _barajar_puzzles() -> void:
	for numero in range(1, CANTIDAD_PUENTES + 1):
		if puentes_listos[numero - 1]:
			continue
		var puzzle := get_node_or_null(RUTA_PUZZLE % numero) as SequencePuzzle
		if not puzzle:
			continue
		var rocas: Array[SequencePuzzleObject] = []
		for hijo in puzzle.get_node("Objects").get_children():
			if hijo is SequencePuzzleObject:
				rocas.append(hijo)
		if rocas.size() < 2:
			continue
		for paso in puzzle.steps:
			var clave := String(paso.get_path())
			paso.sequence = _orden_al_azar(rocas, paso.sequence.size(), ultimo_orden.get(clave, []))
			ultimo_orden[clave] = _nombres_de(paso.sequence)


func _encender_rocas_al_sonar() -> void:
	for numero in range(1, CANTIDAD_PUENTES + 1):
		var puzzle := get_node_or_null(RUTA_PUZZLE % numero) as SequencePuzzle
		if not puzzle:
			continue
		var luz := LuzDeRoca.new()
		add_child(luz)
		luz.vigilar(puzzle)


func _orden_al_azar(
	rocas: Array[SequencePuzzleObject], largo: int, anterior: Array
) -> Array[SequencePuzzleObject]:
	var orden: Array[SequencePuzzleObject] = []
	for intento in INTENTOS_DE_ORDEN_NUEVO:
		orden.clear()
		if largo <= rocas.size():
			var mezcla := rocas.duplicate()
			mezcla.shuffle()
			orden.assign(mezcla.slice(0, largo))
		else:
			for i in largo:
				var opciones := rocas.filter(
					func(roca: SequencePuzzleObject) -> bool:
						return orden.is_empty() or roca != orden[-1]
				)
				orden.append(opciones.pick_random())
		if _nombres_de(orden) != anterior:
			break
	return orden


func _nombres_de(rocas: Array) -> Array:
	return rocas.map(func(roca: Node) -> StringName: return roca.name)


func _marcar_fogatas() -> void:
	var textura := AyudasDeEscena.textura_de_halo(TAMANO_TEXTURA_HALO)
	var suma := AyudasDeEscena.material_de_suma()

	for numero in range(1, CANTIDAD_PUENTES + 1):
		if puentes_listos[numero - 1]:
			continue
		var fogata := _letrero(numero)
		if not fogata or not fogata.interact_area:
			continue
		var halo := Sprite2D.new()
		halo.texture = textura
		halo.material = suma
		halo.modulate = Color(COLOR_HALO_FOGATA, 0.0)
		halo.position = POSICION_HALO_FOGATA
		fogata.add_child(halo)
		_hacer_latir(halo)

		fogata.interact_area.interaction_started.connect(
			func(_jugador: Node, _desde_la_derecha: bool) -> void:
				if is_instance_valid(halo):
					halo.queue_free(),
			CONNECT_ONE_SHOT
		)


func _hacer_latir(halo: Sprite2D) -> void:
	var latido := halo.create_tween().set_loops()
	latido.tween_property(halo, "modulate:a", LATIDO_OPACIDAD_ALTA, LATIDO_DURACION).set_trans(
		Tween.TRANS_SINE
	)
	latido.parallel().tween_property(
		halo, "scale", Vector2.ONE * LATIDO_ESCALA_ALTA, LATIDO_DURACION
	)
	latido.tween_property(halo, "modulate:a", LATIDO_OPACIDAD_BAJA, LATIDO_DURACION).set_trans(
		Tween.TRANS_SINE
	)
	latido.parallel().tween_property(halo, "scale", Vector2.ONE, LATIDO_DURACION)


func _pintar_haces_de_luz() -> void:
	for guardia in $OnTheGround.get_children():
		var luz := guardia.get_node_or_null("DetectionArea/Light") as PointLight2D
		if luz:
			luz.color = COLOR_HAZ_DE_LUZ


func _apagar_rocas() -> void:
	var material_rocas := ShaderMaterial.new()
	material_rocas.shader = ROCAS_APAGADAS
	for capa in $TileMapLayers.get_children():
		if capa is TileMapLayer and String(capa.name).begins_with("Rocas"):
			capa.material = material_rocas


func _marcar_nivel_apagandose() -> void:
	nivel_apagandose = true


func reparar_puente_1() -> void:
	_reparar_puente(1)


func reparar_puente_2() -> void:
	_reparar_puente(2)


func reparar_puente_3() -> void:
	_reparar_puente(3)


func _reparar_puente(numero: int) -> void:
	if nivel_apagandose:
		return
	puentes_listos[numero - 1] = true
	_mostrar_puente_reparado(numero, true)


func _mostrar_puente_reparado(numero: int, retejer: bool = false) -> void:
	var puente := _puente(numero)
	var puente_roto := _puente_roto(numero)
	if retejer:
		_tejer_puente(puente, puente_roto)
		return
	if puente:
		puente.show()
	if puente_roto:
		puente_roto.queue_free()


func _tejer_puente(puente: TileMapLayer, puente_roto: TileMapLayer) -> void:
	if not puente:
		return
	var zona := TileMapMaskBounds.get_world_bounds(puente)
	if puente_roto:
		var trozo_roto: Array[Vector2i] = puente_roto.get_used_cells()
		zona = _zona_sin(zona, TileMapMaskBounds.get_world_bounds(puente_roto))
		var espera := Retejido.momento_en_que_aparecen(puente, trozo_roto)
		get_tree().create_timer(espera).timeout.connect(
			func() -> void:
				if is_instance_valid(puente_roto):
					puente_roto.queue_free()
		)

	var barrera := _crear_barrera(zona)
	puente.set("tiempo_respiro_restante", Retejido.DURACION + RESPIRO_TRAS_TEJER)
	await Retejido.tejer_por_franjas(puente)
	if is_instance_valid(barrera):
		barrera.queue_free()


func _zona_sin(zona: Rect2, roto: Rect2) -> Rect2:
	if zona.size.y >= zona.size.x:
		if roto.get_center().y > zona.get_center().y:
			zona.end.y = roto.position.y
		else:
			zona.position.y = roto.end.y
	elif roto.get_center().x > zona.get_center().x:
		zona.end.x = roto.position.x
	else:
		zona.position.x = roto.end.x
	return zona


func _crear_barrera(zona: Rect2) -> StaticBody2D:
	var barrera := StaticBody2D.new()
	barrera.collision_layer = CAPA_PAREDES
	barrera.collision_mask = 0
	var forma := CollisionShape2D.new()
	var rectangulo := RectangleShape2D.new()
	rectangulo.size = zona.size
	forma.shape = rectangulo
	barrera.add_child(forma)
	add_child(barrera)
	barrera.global_position = zona.get_center()
	return barrera


func _restaurar_puente_y_borrar_hilo(numero: int) -> void:
	_mostrar_puente_reparado(numero)

	var coleccionable := get_node_or_null(RUTA_COLECCIONABLE % numero)
	if coleccionable:
		for conexion in coleccionable.tree_exited.get_connections():
			coleccionable.tree_exited.disconnect(conexion.callable)
		coleccionable.queue_free()

	var letrero := _letrero(numero)
	if not letrero:
		push_warning("No se encontró el letrero en la ruta: %s" % (RUTA_LETRERO % [numero, numero]))
		return

	letrero.is_solved = true
	if letrero.animated_sprite:
		letrero.animated_sprite.play(&"solved")
