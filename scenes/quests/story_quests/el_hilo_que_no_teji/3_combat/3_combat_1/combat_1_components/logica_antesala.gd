# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D
## La antesala: el nivel 3.2 en pequeño.

const AyudasDeEscena = preload("../../../shared/scripts/ayudas_de_escena.gd")
const BendicionDeLazaro = preload("../../../shared/scripts/bendicion_de_lazaro.gd")
const BendicionDeLuto = preload("../../../shared/scripts/bendicion_de_luto.gd")
const FlechaDeEmpuje = preload("../../../shared/scripts/flecha_de_empuje.gd")

## elian_entrance.wav
const SONIDO_ENTRADA_ELIAN: AudioStream = preload("uid://5m257w00i35m")
## el_hilo_que_no_teji_combat_round_1.dialogue
const DIALOGO: DialogueResource = preload("uid://buwv0q8u3r1i5")
const TITULO_AL_BAJAR: String = "start"
const TITULO_VOZ_LEJANA: String = "voz_lejana"
const FUNDIDO_SONIDO: float = 2.0
const BUS_SFX: StringName = &"SFX"
const GRUPO_SOMBRAS: StringName = &"throwing_enemy"
const GRUPO_PROYECTILES: StringName = &"projectiles"
const RUTA_OBJETOS: String = "OnTheGround/"
const ETIQUETA_IRA: String = "Ira"
const COLOR_IRA: Color = Color(0.6, 0.6, 0.6)
const INTENSIDAD_PESADILLA: float = 0.35

const PUENTE_DE_CADA_JARRON: Dictionary[String, Array] = {
	"FillingBarrel": ["PuenteRoto2", "PuenteReparado2"],
	"FillingBarrel3": ["PuenteRoto", "PuenteReparado"],
}
const ESCALERA: String = "Escalera"
const PASTO: String = "SubsueloPasto"
const CAPAS_DE_SUELO: Array[String] = [PASTO, "Madera", ESCALERA]
const CAPA_DEL_LAGO: String = "TintaLagoFill"
const CAPAS_SOLO_PARA_LINO: Array[String] = ["TintaLago", "SubsueloTierra"]
# Capa de colisión 512: los proyectiles no la tienen en su máscara, solo Lino
const CHOQUE_SOLO_LINO: int = 512
const VELOCIDAD_PROYECTIL: float = 22.0
const SEGUNDOS_ENTRE_DISPAROS: float = 4.0
const Z_PROYECTILES: int = 20
const ID_FUENTE_ORILLA: int = 0

# static para que los jarrones llenos sobrevivan al recargar la escena tras morir
static var jarrones_guardados: Array[String] = []

@export var orbes_por_jarron: int = 2

var jarrones_llenos: int = 0
var orillas: TileMapLayer
var puentes_tejidos: Array[TileMapLayer] = []
var bendicion: BendicionDeLazaro

@onready var jugador: Player = $OnTheGround/Player
@onready var capas: Node2D = $TileMapLayers
@onready var panel_pensamiento: Control = get_node_or_null("HUD/PanelContainer")


func _ready() -> void:
	add_child(GolpesALino.new(jugador, panel_pensamiento))
	if ElHiloQueNoTejiState.es_partida_nueva_para(scene_file_path):
		jarrones_guardados.clear()
		BendicionDeLazaro.olvidar(scene_file_path)
	child_entered_tree.connect(_subir_proyectil)

	_configurar_sombras()
	_conectar_jarrones()

	var pesadilla := Pesadilla.new()
	pesadilla.grupos = [GRUPO_SOMBRAS]
	pesadilla.intensidad_maxima = INTENSIDAD_PESADILLA
	add_child(pesadilla)

	_mostrar_puentes_rotos()

	_dejar_pasar_los_proyectiles()
	_restaurar_jarrones_llenos()
	_crear_orillas()
	_preparar_bendiciones()

	var cuerda := DescensoPorLaCuerda.new()
	cuerda.bajada_terminada.connect(_decir_al_bajar)
	add_child(cuerda)
	add_child(ReaparicionEnHilo.new())


## Las ayudas de Lázaro y de Luto, las mismas del nivel 3.2. Solo hacen falta mientras
## quede algún jarrón por llenar.
func _preparar_bendiciones() -> void:
	if jarrones_llenos >= PUENTE_DE_CADA_JARRON.size():
		return
	var flecha := FlechaDeEmpuje.new()
	flecha.jugador = jugador
	for nombre in PUENTE_DE_CADA_JARRON:
		flecha.jarrones.append(get_node_or_null(RUTA_OBJETOS + nombre))
	add_child(flecha)
	bendicion = BendicionDeLazaro.new()
	bendicion.jugador = jugador
	bendicion.nivel = scene_file_path
	bendicion.flecha = flecha
	add_child(bendicion)
	var bendicion_de_luto := BendicionDeLuto.new()
	bendicion_de_luto.jugador = jugador
	bendicion_de_luto.nivel = scene_file_path
	add_child(bendicion_de_luto)


func _sombras() -> Array[Node]:
	var propias: Array[Node] = []
	for sombra in get_tree().get_nodes_in_group(GRUPO_SOMBRAS):
		if is_ancestor_of(sombra):
			propias.append(sombra)
	return propias


func _configurar_sombras() -> void:
	var etiquetas: Array[String] = [ETIQUETA_IRA]
	var colores: Dictionary[String, Color] = {ETIQUETA_IRA: COLOR_IRA}
	for sombra in _sombras():
		sombra.allowed_labels = etiquetas
		sombra.color_per_label = colores
		sombra.projectile_speed = VELOCIDAD_PROYECTIL
		sombra.throwing_period = SEGUNDOS_ENTRE_DISPAROS


func _conectar_jarrones() -> void:
	for nombre in PUENTE_DE_CADA_JARRON:
		var jarron := get_node_or_null(RUTA_OBJETOS + nombre) as FillingBarrel
		if jarron:
			jarron.needed_amount = orbes_por_jarron
			jarron.completed.connect(_al_llenar_jarron.bind(nombre))


func _mostrar_puentes_rotos() -> void:
	for nombre in PUENTE_DE_CADA_JARRON:
		var roto := _puente_roto(nombre)
		var reparado := _puente_reparado(nombre)
		if roto:
			roto.show()
			roto.enabled = true
		if reparado:
			reparado.enabled = false


func _subir_proyectil(nodo: Node) -> void:
	if nodo is Node2D and nodo.is_in_group("projectiles"):
		nodo.z_index = maxi(nodo.z_index, Z_PROYECTILES)
		# Todos los proyectiles de esta sala los lanzan sombras, así que todos llevan flecha.
		nodo.set_meta(FlechaDeEmpuje.META_CON_FLECHA, true)


func _al_llenar_jarron(nombre: String) -> void:
	jarrones_llenos += 1
	jarrones_guardados.append(nombre)
	if bendicion:
		bendicion.reiniciar_cuenta()
	_reparar_el_puente(_puente_roto(nombre), _puente_reparado(nombre))
	if jarrones_llenos >= PUENTE_DE_CADA_JARRON.size():
		_despejar_la_antesala()


func _reparar_el_puente(roto: TileMapLayer, reparado: TileMapLayer) -> void:
	if roto:
		Retejido.desaparecer(roto, false, Retejido.DURACION_BREVE)
	if not reparado:
		return
	await Retejido.tejer_por_franjas(reparado)
	_quitar_bordes_bajo(reparado)
	puentes_tejidos.append(reparado)
	_crear_orillas()


func _restaurar_jarrones_llenos() -> void:
	for nombre in jarrones_guardados:
		var jarron := get_node_or_null(RUTA_OBJETOS + nombre)
		if jarron:
			jarron.queue_free()
		jarrones_llenos += 1
		var roto := _puente_roto(nombre)
		var reparado := _puente_reparado(nombre)
		if roto:
			roto.enabled = false
		if reparado:
			# La capa empieza oculta en la escena: sin show() el puente funciona pero no se ve.
			reparado.show()
			reparado.enabled = true
			_quitar_bordes_bajo(reparado)
			puentes_tejidos.append(reparado)
	if jarrones_llenos >= PUENTE_DE_CADA_JARRON.size():
		_quitar_sombras()


func _quitar_sombras() -> void:
	for sombra in _sombras():
		sombra.queue_free()


func _despejar_la_antesala() -> void:
	_quitar_sombras()
	if bendicion:
		bendicion.queue_free()
	get_tree().call_group(GRUPO_PROYECTILES, "remove")
	_sonar_entrada_de_elian()
	_decir_desde_lejos()


func _capa(nombre: String) -> TileMapLayer:
	return capas.get_node_or_null(nombre) as TileMapLayer


func _puente_roto(jarron: String) -> TileMapLayer:
	return _capa(PUENTE_DE_CADA_JARRON[jarron][0])


func _puente_reparado(jarron: String) -> TileMapLayer:
	return _capa(PUENTE_DE_CADA_JARRON[jarron][1])


## Los proyectiles cruzan los bordes del lago; si no, se deshacen antes de llegar.
func _dejar_pasar_los_proyectiles() -> void:
	for nombre in CAPAS_SOLO_PARA_LINO:
		var capa := _capa(nombre)
		if not capa or not capa.tile_set:
			continue
		# duplicado porque el TileSet es un recurso compartido con otros niveles
		var tiles := capa.tile_set.duplicate() as TileSet
		for capa_fisica in tiles.get_physics_layers_count():
			tiles.set_physics_layer_collision_layer(capa_fisica, CHOQUE_SOLO_LINO)
		capa.tile_set = tiles


func _quitar_bordes_bajo(puente: TileMapLayer) -> void:
	for nombre in CAPAS_SOLO_PARA_LINO:
		var capa := _capa(nombre)
		if not capa:
			continue
		for celda in capa.get_used_cells():
			var lugar := capa.to_global(capa.map_to_local(celda))
			if puente.get_cell_source_id(puente.local_to_map(puente.to_local(lugar))) != -1:
				capa.erase_cell(celda)


func _crear_orillas() -> void:
	var lago := _capa(CAPA_DEL_LAGO)
	if not lago:
		return
	if not orillas:
		orillas = TileMapLayer.new()
		orillas.name = "OrillasDelLago"
		orillas.visible = false
		orillas.position = lago.position
		orillas.tile_set = _tiles_de_orilla(lago.tile_set.tile_size)
		capas.add_child(orillas)
	orillas.clear()
	var suelos: Array[TileMapLayer] = []
	for nombre in CAPAS_DE_SUELO:
		if _capa(nombre):
			suelos.append(_capa(nombre))
	suelos.append_array(puentes_tejidos)
	for celda in lago.get_used_cells():
		var lugar := lago.to_global(lago.map_to_local(celda))
		if not _hay_suelo(suelos, lugar):
			orillas.set_cell(celda, ID_FUENTE_ORILLA, Vector2i.ZERO)


func _hay_suelo(suelos: Array[TileMapLayer], lugar: Vector2) -> bool:
	for suelo in suelos:
		if suelo.get_cell_source_id(suelo.local_to_map(suelo.to_local(lugar))) != -1:
			return true
	return false


func _tiles_de_orilla(tamano: Vector2i) -> TileSet:
	var tiles := TileSet.new()
	tiles.tile_size = tamano
	tiles.add_physics_layer()
	tiles.set_physics_layer_collision_layer(0, CHOQUE_SOLO_LINO)
	tiles.set_physics_layer_collision_mask(0, 0)
	var imagen := Image.create_empty(tamano.x, tamano.y, false, Image.FORMAT_RGBA8)
	var fuente := TileSetAtlasSource.new()
	fuente.texture = ImageTexture.create_from_image(imagen)
	fuente.texture_region_size = tamano
	tiles.add_source(fuente, ID_FUENTE_ORILLA)
	fuente.create_tile(Vector2i.ZERO)
	var medio := Vector2(tamano) / 2.0
	var datos := fuente.get_tile_data(Vector2i.ZERO, 0)
	datos.add_collision_polygon(0)
	datos.set_collision_polygon_points(
		0,
		0,
		PackedVector2Array([-medio, Vector2(medio.x, -medio.y), medio, Vector2(-medio.x, medio.y)])
	)
	return tiles


func _sonar_entrada_de_elian() -> void:
	var sonido := AudioStreamPlayer.new()
	sonido.stream = SONIDO_ENTRADA_ELIAN
	sonido.bus = BUS_SFX
	add_child(sonido)
	sonido.play()
	var apagar := sonido.create_tween()
	apagar.tween_interval(maxf(SONIDO_ENTRADA_ELIAN.get_length() - FUNDIDO_SONIDO, 0.0))
	# Se baja el volumen real (no los decibelios) para que la bajada se oiga pareja.
	apagar.tween_method(
		func(volumen: float) -> void: sonido.volume_db = linear_to_db(volumen),
		1.0,
		0.0,
		FUNDIDO_SONIDO
	)
	apagar.tween_callback(sonido.queue_free)


func _decir_al_bajar() -> void:
	DialogueManager.show_dialogue_balloon(DIALOGO, TITULO_AL_BAJAR)


func _decir_desde_lejos() -> void:
	await AyudasDeEscena.mostrar_globo_arriba(DIALOGO, TITULO_VOZ_LEJANA)
