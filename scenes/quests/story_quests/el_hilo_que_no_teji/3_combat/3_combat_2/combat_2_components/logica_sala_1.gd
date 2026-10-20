# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D
## La sala del Archivero (nivel 3.2).

const AyudasDeEscena = preload("../../../shared/scripts/ayudas_de_escena.gd")
const EfectosFinal = preload("efectos_final.gd")
const BendicionDeLazaro = preload("../../../shared/scripts/bendicion_de_lazaro.gd")
const BendicionDeLuto = preload("../../../shared/scripts/bendicion_de_luto.gd")
const FlechaDeEmpuje = preload("../../../shared/scripts/flecha_de_empuje.gd")
const CinematicaFinal = preload("cinematica_final.gd")
const TextoPensamiento = preload("../../../shared/scripts/texto_pensamiento.gd")
const SaturacionManager = preload("../../../shared/scripts/saturacion_manager.gd")

const NODO_INTERACCION: NodePath = ^"InteractArea"
const NIVEL: String = "combat_2"
const RUTA_OBJETOS: String = "OnTheGround/"
const GRUPO_JUGADOR: StringName = &"player"
const GRUPO_PROYECTILES: StringName = &"projectiles"
const GRUPO_SOMBRAS: StringName = &"throwing_enemy"
const BUS_SFX: StringName = &"SFX"
const ETIQUETA_IRA: String = "Ira"
const COLOR_IRA: Color = Color(0.6, 0.6, 0.6)
const INTENSIDAD_PESADILLA: float = 0.35
const HILOS_PARA_ABRIR_LA_PUERTA: int = 2
const HILOS_PARA_ABRIR_LA_SALIDA: int = 3
const TITULO_PRIMER_HILO: StringName = &"hilo_1"
const TITULO_SEGUNDO_HILO: StringName = &"hilo_2"
const COLOR_QUE_DEVUELVE_UN_HILO: float = 0.25
const FUNDIDO_SONIDO: float = 0.6
const VOLUMEN_APAGADO: float = -60.0
const LUZ_POR_HILOS: Array[Color] = [
	Color(0.4, 0.4, 0.4), Color(0.6, 0.6, 0.6), Color(0.8, 0.8, 0.8), Color(1.0, 1.0, 1.0)
]

## Títulos de las frases en dialogos_frases.dialogue.
const TITULO_FRASE_PUERTA_CERRADA: String = "puerta_cerrada"
const TITULOS_ARCHIVERO: Array[String] = ["archivero_1", "archivero_2", "archivero_3"]
## elian_laugh.wav
const RISA_ELIAN: AudioStream = preload("uid://b6ar0l4qv6p7k")
const SONIDOS_JARRONES_ELIAN: Array[AudioStream] = [
	preload("uid://thc756f2g4sw"), preload("uid://dl5qpyo38pjaa"), preload("uid://lsgarkg6mjsn")
]

const ZOOM_A_LA_PUERTA := Vector2(1.5, 1.5)
const TIEMPO_IDA_A_LA_PUERTA: float = 1.2
const PAUSA_ANTES_DE_TEMBLAR: float = 0.2
const TEMBLORES_DE_LA_PUERTA: int = 30
const DURACION_TEMBLOR_PUERTA: float = 0.04
const DURACION_REPOSO_PUERTA: float = 0.05
const FUERZA_TEMBLOR_PUERTA: float = 4.0
const PAUSA_TRAS_ABRIR_PUERTA: float = 1.2
const TIEMPO_VUELTA_A_LINO: float = 0.8

const SACUDIDAS_DE_PANTALLA: int = 10
const FUERZA_SACUDIDA_PANTALLA: float = 8.0
const DURACION_SACUDIDA_PANTALLA: float = 0.05

const TAMANO_ZONA_PUERTA_CERRADA := Vector2(260, 160)
const DESPLAZAMIENTO_ZONA_PUERTA_CERRADA := Vector2(0, 80)
const DISTANCIA_GLOBO_ARCHIVERO: float = 120.0

const JARRONES_IZQ: Array[String] = ["FillingBarrel", "FillingBarrel2"]
const JARRONES_DER: Array[String] = ["FillingBarrel3", "FillingBarrel4"]
const JARRONES_BOSS: Array[String] = ["FillingBarrel5", "FillingBarrel6", "FillingBarrel7"]
const LETRERO_Y_ENEMIGO_DE_JARRON: Dictionary[String, Array] = {
	"FillingBarrel": ["Sign5", "ThrowingEnemy"],
	"FillingBarrel2": ["Sign4", "ThrowingEnemy2"],
	"FillingBarrel3": ["Sign6", "ThrowingEnemy4"],
	"FillingBarrel4": ["Sign7", "ThrowingEnemy3"],
	"FillingBarrel5": ["Sign", ""],
	"FillingBarrel6": ["Sign3", ""],
	"FillingBarrel7": ["Sign2", ""],
}

# Lo que se guarda aunque Lino se deshile (se borra al empezar una partida nueva).
static var estado_hilo_izq: bool = false
static var estado_hilo_der: bool = false
static var estado_hilo_central: bool = false
static var jarrones_completados: Dictionary[String, bool] = {}
static var frase_puerta_mostrada: bool = false
static var acercamiento_elian_visto: bool = false

@export_category("Cinemática final")
@export var dialogo_lazaro: DialogueResource
@export var titulo_dialogo_lazaro: String = "lazaro_final"
@export var escena_outro: PackedScene
@export var nodo_vacio: Node2D

var risa_central_sonada: bool = false
var jarrones_izq_completados: int = 0
var jarrones_der_completados: int = 0
var jarrones_boss_completados: int = 0
var hilos_recogidos: int = 0
var alas_limpiadas: int = 0
var boss_derrotado: bool = false
var panel_archivero: TextoPensamiento
var sonido_risa: AudioStreamPlayer
var golpes: GolpesALino
var efectos: EfectosFinal
var bendicion: BendicionDeLazaro
var bendicion_de_luto: BendicionDeLuto
var pesadilla: Pesadilla

@onready var jugador: Player = $OnTheGround/Player
@onready var sprite_jugador: AnimatedSprite2D = jugador.get_node("%PlayerSprite")
@onready var panel_pensamiento: TextoPensamiento = $HUD/PanelContainer
@onready var canvas_modulate: CanvasModulate = get_node_or_null("CanvasModulate")
@onready var saturacion_manager: SaturacionManager = get_node_or_null("SaturacionManager")

@onready var puerta_central: Node2D = $"OnTheGround/Door Enter"
@onready var puerta_salida: Node2D = $"OnTheGround/LevelExit/Door Exit"
@onready var hilo_izq: StealthCollectible = $OnTheGround/CollectibleItem_Izq
@onready var hilo_der: StealthCollectible = $OnTheGround/CollectibleItem_Der
@onready var hilo_central: StealthCollectible = $OnTheGround/CollectibleItem_Centro

@onready var sombras_izq: Array[Node] = [$OnTheGround/ThrowingEnemy, $OnTheGround/ThrowingEnemy2]
@onready var sombras_der: Array[Node] = [$OnTheGround/ThrowingEnemy3, $OnTheGround/ThrowingEnemy4]
@onready var elian: Node2D = $OnTheGround/ThrowingEnemy8
@onready var jarrones_izq: Array[Node] = [$OnTheGround/FillingBarrel, $OnTheGround/FillingBarrel2]
@onready var jarrones_der: Array[Node] = [$OnTheGround/FillingBarrel3, $OnTheGround/FillingBarrel4]
@onready var jarrones_boss: Array[Node] = [
	$OnTheGround/FillingBarrel5, $OnTheGround/FillingBarrel6, $OnTheGround/FillingBarrel7
]

@onready var lazaro: AnimatedSprite2D = $OnTheGround2/Lazaro
@onready var luto: Node2D = $OnTheGround2/Luto
@onready var bloqueo_puente: StaticBody2D = $OnTheGround/BloqueoPuente
@onready var particulas_perdon: GPUParticles2D = $OnTheGround/ParticulasPerdon
@onready var puente_boss_final: TileMapLayer = $TileMapLayers/PuenteBossFinal


func _ready() -> void:
	ElHiloQueNoTejiIdiomas.registrar()
	if ElHiloQueNoTejiState.es_partida_nueva_para(NIVEL):
		_olvidar_lo_guardado()

	golpes = GolpesALino.new(jugador, panel_pensamiento)
	add_child(golpes)
	_preparar_efectos()

	_configurar_sombras()

	for jarron in jarrones_izq + jarrones_der + jarrones_boss:
		if is_instance_valid(jarron):
			jarron.completed.connect(_al_completar_jarron.bind(String(jarron.name)))

	if is_instance_valid(puente_boss_final):
		puente_boss_final.enabled = estado_hilo_central

	_restaurar_hilos_recogidos()
	_preparar_voz_del_archivero()
	_restaurar_jarrones_completados()

	_actualizar_color_ambiente()
	if hilos_recogidos >= HILOS_PARA_ABRIR_LA_PUERTA and is_instance_valid(puerta_central):
		puerta_central.open()
	if hilos_recogidos >= HILOS_PARA_ABRIR_LA_SALIDA and is_instance_valid(puerta_salida):
		puerta_salida.open()
	if hilos_recogidos < HILOS_PARA_ABRIR_LA_PUERTA and not frase_puerta_mostrada:
		_crear_aviso_puerta_cerrada()

	var reaparicion := ReaparicionEnHilo.new()
	reaparicion.omitir_frase = _aparece_luto_al_reaparecer
	add_child(reaparicion)
	if is_instance_valid(luto):
		luto.add_child(EfectoFantasma.new())
	pesadilla = Pesadilla.new()
	pesadilla.grupos = [GRUPO_SOMBRAS]
	pesadilla.intensidad_maxima = INTENSIDAD_PESADILLA
	if boss_derrotado:
		pesadilla.intensidad_fija = 0.0  # Se restauró antes de que existiera.
	add_child(pesadilla)
	_preparar_ayudas()


func _configurar_sombras() -> void:
	var etiquetas: Array[String] = [ETIQUETA_IRA]
	var colores: Dictionary[String, Color] = {ETIQUETA_IRA: COLOR_IRA}
	for sombra in get_tree().get_nodes_in_group(GRUPO_SOMBRAS):
		if is_ancestor_of(sombra):
			sombra.allowed_labels = etiquetas
			sombra.color_per_label = colores


func _olvidar_lo_guardado() -> void:
	estado_hilo_izq = false
	estado_hilo_der = false
	estado_hilo_central = false
	jarrones_completados.clear()
	frase_puerta_mostrada = false
	acercamiento_elian_visto = false
	BendicionDeLazaro.olvidar(NIVEL)


func _preparar_efectos() -> void:
	efectos = EfectosFinal.new()
	efectos.puerta = puerta_salida
	efectos.vacios = [nodo_vacio, get_node_or_null("OnTheGround/VoidSpreadingEnemy2")]
	efectos.elian = elian
	efectos.jugador = jugador
	if is_instance_valid(elian):
		AnimacionDeElian.aplicar(elian)
	if is_instance_valid(saturacion_manager):
		efectos.material_mundo = saturacion_manager.material_mundo
	if is_instance_valid(hilo_central):
		efectos.origen_ondas = hilo_central.global_position
	add_child(efectos)
	if not estado_hilo_central:
		efectos.ocultar_puerta()
		# El último hilo no devuelve el color de golpe: lo hacen las ondas.
		if is_instance_valid(saturacion_manager):
			saturacion_manager.tope_saturacion_mundo = efectos.SATURACION_ANTES_DEL_ULTIMO_HILO

	child_entered_tree.connect(efectos.subir_proyectil)
	if is_instance_valid(hilo_central) and hilo_central.has_node(NODO_INTERACCION):
		hilo_central.get_node(NODO_INTERACCION).interaction_started.connect(
			efectos.bajar_musica.unbind(2)
		)


func _preparar_ayudas() -> void:
	efectos.sombras_con_flecha = sombras_izq + sombras_der + [elian]
	efectos.dormir_vacio()
	var flecha := FlechaDeEmpuje.new()
	flecha.jugador = jugador
	flecha.jarrones = jarrones_izq + jarrones_der + jarrones_boss
	add_child(flecha)
	bendicion = BendicionDeLazaro.new()
	bendicion.jugador = jugador
	bendicion.nivel = NIVEL
	bendicion.flecha = flecha
	bendicion.elian = elian
	add_child(bendicion)
	# Luto solo ayuda hasta que se abre la puerta de Elián: ahí Lázaro lo llama.
	if hilos_recogidos < HILOS_PARA_ABRIR_LA_PUERTA:
		bendicion_de_luto = BendicionDeLuto.new()
		bendicion_de_luto.jugador = jugador
		bendicion_de_luto.nivel = NIVEL
		add_child(bendicion_de_luto)


## La primera vez que Luto aparece, su llegada ya acompaña a Lino: no se suma la frase de siempre.
func _aparece_luto_al_reaparecer() -> bool:
	var sin_abrir: bool = hilos_recogidos < HILOS_PARA_ABRIR_LA_PUERTA
	return sin_abrir and BendicionDeLuto.aparece_al_reaparecer(NIVEL)


func _restaurar_hilos_recogidos() -> void:
	if estado_hilo_izq:
		_restaurar_ala_recogida(sombras_izq + jarrones_izq + [hilo_izq])
	else:
		_esperar_a_que_recojan(hilo_izq, "izq")

	if estado_hilo_der:
		_restaurar_ala_recogida(sombras_der + jarrones_der + [hilo_der])
	else:
		_esperar_a_que_recojan(hilo_der, "der")

	if estado_hilo_central:
		_quitar(jarrones_boss + [elian, hilo_central, lazaro, luto])
		hilos_recogidos += 1
	else:
		_esperar_a_que_recojan(hilo_central, "central")


func _restaurar_ala_recogida(nodos_del_ala: Array) -> void:
	_quitar(nodos_del_ala)
	hilos_recogidos += 1
	alas_limpiadas += 1


func _esperar_a_que_recojan(hilo: StealthCollectible, id_hilo: String) -> void:
	if is_instance_valid(hilo):
		hilo.revealed = false
		# el hilo se libera al recogerlo, por eso se avisa con tree_exited
		hilo.tree_exited.connect(_al_recoger_hilo.bind(id_hilo))


func _quitar(nodos: Array) -> void:
	for nodo in nodos:
		if is_instance_valid(nodo):
			nodo.queue_free()


func _preparar_voz_del_archivero() -> void:
	if not is_instance_valid(panel_pensamiento) or not is_instance_valid(elian):
		return
	# copia aparte para que la voz de Elián no pise el globo de Lino
	panel_archivero = panel_pensamiento.duplicate() as TextoPensamiento
	panel_pensamiento.get_parent().add_child(panel_archivero)
	panel_archivero.jugador_objetivo = elian
	panel_archivero.distancia_cabeza = DISTANCIA_GLOBO_ARCHIVERO


func _reir(tono: float = 1.0, sonido: AudioStream = RISA_ELIAN) -> void:
	if is_instance_valid(sonido_risa) and sonido_risa.playing:
		var anterior := sonido_risa
		var apagar := anterior.create_tween()
		apagar.tween_property(anterior, "volume_db", VOLUMEN_APAGADO, FUNDIDO_SONIDO)
		apagar.tween_callback(anterior.queue_free)

	sonido_risa = AudioStreamPlayer.new()
	sonido_risa.stream = sonido
	sonido_risa.bus = BUS_SFX
	sonido_risa.pitch_scale = tono
	# Sigue sonando aunque el juego se pause para un diálogo.
	sonido_risa.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(sonido_risa)
	sonido_risa.play()

	var duracion: float = sonido.get_length() / tono
	var cola := sonido_risa.create_tween()
	cola.tween_interval(maxf(duracion - FUNDIDO_SONIDO, 0.0))
	cola.tween_property(sonido_risa, "volume_db", VOLUMEN_APAGADO, FUNDIDO_SONIDO)
	cola.tween_callback(sonido_risa.queue_free)


func _decir_como_archivero(titulo: String) -> void:
	var frase := await ElHiloQueNoTejiIdiomas.frase(titulo)
	if is_instance_valid(panel_archivero):
		panel_archivero.mostrar_pensamiento(frase)


func _crear_aviso_puerta_cerrada() -> void:
	if not is_instance_valid(puerta_central):
		return
	var zona := Area2D.new()
	zona.collision_mask = $OnTheGround/TriggerCentral.collision_mask
	var forma := CollisionShape2D.new()
	var rectangulo := RectangleShape2D.new()
	rectangulo.size = TAMANO_ZONA_PUERTA_CERRADA
	forma.shape = rectangulo
	zona.add_child(forma)
	$OnTheGround.add_child(zona)
	zona.global_position = puerta_central.global_position + DESPLAZAMIENTO_ZONA_PUERTA_CERRADA
	zona.body_entered.connect(_al_llegar_a_puerta_cerrada.bind(zona))


func _al_llegar_a_puerta_cerrada(body: Node2D, zona: Area2D) -> void:
	if not body.is_in_group(GRUPO_JUGADOR):
		return
	zona.queue_free()
	if frase_puerta_mostrada or hilos_recogidos >= HILOS_PARA_ABRIR_LA_PUERTA:
		return
	frase_puerta_mostrada = true
	var frase := await ElHiloQueNoTejiIdiomas.frase(TITULO_FRASE_PUERTA_CERRADA)
	if is_instance_valid(panel_pensamiento):
		panel_pensamiento.mostrar_pensamiento(frase)


func _actualizar_color_ambiente() -> void:
	if is_instance_valid(canvas_modulate):
		canvas_modulate.color = LUZ_POR_HILOS[mini(hilos_recogidos, LUZ_POR_HILOS.size() - 1)]


func _sacudir_pantalla() -> void:
	var camara := get_viewport().get_camera_2d()
	if not is_instance_valid(camara):
		return
	var sacudir := create_tween()
	for _sacudida in SACUDIDAS_DE_PANTALLA:
		var desvio := Vector2(
			randf_range(-FUERZA_SACUDIDA_PANTALLA, FUERZA_SACUDIDA_PANTALLA),
			randf_range(-FUERZA_SACUDIDA_PANTALLA, FUERZA_SACUDIDA_PANTALLA)
		)
		sacudir.tween_property(camara, "offset", desvio, DURACION_SACUDIDA_PANTALLA)
	sacudir.tween_property(camara, "offset", Vector2.ZERO, DURACION_SACUDIDA_PANTALLA)


func _al_recoger_hilo(id_hilo: String) -> void:
	if not is_inside_tree():
		return

	match id_hilo:
		"izq":
			estado_hilo_izq = true
		"der":
			estado_hilo_der = true
		"central":
			estado_hilo_central = true

	hilos_recogidos += 1
	_actualizar_color_ambiente()
	var gris_antes := golpes.gris_visible()
	golpes.gris = maxf(golpes.gris - COLOR_QUE_DEVUELVE_UN_HILO, 0.0)
	efectos.recuperar_color(golpes.poner_gris, sprite_jugador, gris_antes, golpes.gris)

	if id_hilo == "central":
		_empezar_cinematica_final()
	elif hilos_recogidos == HILOS_PARA_ABRIR_LA_PUERTA:
		_cinematica_apertura_puerta()


func _empezar_cinematica_final() -> void:
	jugador.take_control(self)
	jugador.velocity = Vector2.ZERO
	golpes.proteger_para_siempre()
	# nada puede dañar ni atrapar a Lino: el vacío casi lo alcanza, pero no lo mata
	jugador.set_deferred("collision_layer", 0)
	efectos.desactivar_captura()
	if is_instance_valid(panel_archivero):
		panel_archivero.hide()

	var cinematica := CinematicaFinal.new()
	cinematica.jugador = jugador
	cinematica.elian = elian
	cinematica.lazaro = lazaro
	cinematica.luto = luto
	cinematica.puerta_salida = puerta_salida
	cinematica.particulas_perdon = particulas_perdon
	cinematica.efectos = efectos
	cinematica.saturacion_manager = saturacion_manager
	cinematica.dialogo_lazaro = dialogo_lazaro
	cinematica.titulo_dialogo_lazaro = titulo_dialogo_lazaro
	cinematica.escena_outro = escena_outro
	cinematica.interfaz = [$HUD, $ScreenOverlay]
	cinematica.reir = _reir
	add_child(cinematica)
	cinematica.reproducir()


func _cinematica_apertura_puerta() -> void:
	var foco_camara := get_node_or_null("TileMapLayers/FocoCamaraPuerta") as Node2D
	var destino: Vector2 = (
		foco_camara.global_position if foco_camara else puerta_central.global_position
	)

	jugador.take_control(self)
	jugador.velocity = Vector2.ZERO

	var camara_de_lino := get_viewport().get_camera_2d()
	var camara := AyudasDeEscena.camara_como(camara_de_lino)
	add_child(camara)
	camara.make_current()

	var cinematica := create_tween()
	cinematica.tween_property(camara, "global_position", destino, TIEMPO_IDA_A_LA_PUERTA).set_trans(
		Tween.TRANS_SINE
	)
	(
		cinematica
		. parallel()
		. tween_property(camara, "zoom", ZOOM_A_LA_PUERTA, TIEMPO_IDA_A_LA_PUERTA)
		. set_trans(Tween.TRANS_SINE)
	)
	cinematica.tween_interval(PAUSA_ANTES_DE_TEMBLAR)

	_temblar_puerta(cinematica)
	cinematica.tween_callback(puerta_central.open)
	cinematica.tween_callback(_sacudir_pantalla)

	cinematica.tween_interval(PAUSA_TRAS_ABRIR_PUERTA)
	(
		cinematica
		. tween_property(
			camara,
			"global_position",
			camara_de_lino.get_screen_center_position(),
			TIEMPO_VUELTA_A_LINO
		)
		. set_trans(Tween.TRANS_QUAD)
	)
	cinematica.parallel().tween_property(camara, "zoom", camara_de_lino.zoom, TIEMPO_VUELTA_A_LINO)
	await cinematica.finished

	camara_de_lino.make_current()
	camara.queue_free()
	# Lino no se mueve hasta que Luto se haya ido, para no cruzarse con la entrada a la sala.
	if is_instance_valid(bendicion_de_luto):
		await bendicion_de_luto.despedirse()
	jugador.return_control(self)


func _temblar_puerta(cinematica: Tween) -> void:
	var origen_puerta: Vector2 = puerta_central.position
	for i in TEMBLORES_DE_LA_PUERTA:
		var fuerza := float(i) / TEMBLORES_DE_LA_PUERTA
		var sacudida := (
			Vector2(
				randf_range(-FUERZA_TEMBLOR_PUERTA, FUERZA_TEMBLOR_PUERTA),
				randf_range(-FUERZA_TEMBLOR_PUERTA, FUERZA_TEMBLOR_PUERTA)
			)
			* fuerza
		)
		cinematica.tween_property(
			puerta_central, "position", origen_puerta + sacudida, DURACION_TEMBLOR_PUERTA
		)
	cinematica.tween_property(puerta_central, "position", origen_puerta, DURACION_REPOSO_PUERTA)


func _al_completar_jarron(nombre: String) -> void:
	jarrones_completados[nombre] = true
	bendicion.reiniciar_cuenta()
	_aplicar_jarron_completado(nombre, false)


func _restaurar_jarrones_completados() -> void:
	for nombre in jarrones_completados:
		var jarron := get_node_or_null(RUTA_OBJETOS + nombre)
		if not is_instance_valid(jarron) or jarron.is_queued_for_deletion():
			continue  # Ya se quitó al restaurar un hilo recogido.
		jarron.queue_free()
		_aplicar_jarron_completado(nombre, true)


func _aplicar_jarron_completado(nombre: String, restaurando: bool) -> void:
	for ruta in LETRERO_Y_ENEMIGO_DE_JARRON.get(nombre, []):
		if ruta != "":
			_quitar([get_node_or_null(RUTA_OBJETOS + ruta)])

	if nombre in JARRONES_IZQ:
		jarrones_izq_completados += 1
		if jarrones_izq_completados == JARRONES_IZQ.size():
			_limpiar_ala(sombras_izq, hilo_izq)
	elif nombre in JARRONES_DER:
		jarrones_der_completados += 1
		if jarrones_der_completados == JARRONES_DER.size():
			_limpiar_ala(sombras_der, hilo_der)
	elif nombre in JARRONES_BOSS:
		_al_completar_jarron_boss(restaurando)


func _limpiar_ala(sombras: Array[Node], hilo: StealthCollectible) -> void:
	alas_limpiadas += 1
	_quitar(sombras)
	get_tree().call_group(GRUPO_PROYECTILES, "remove")
	if is_instance_valid(hilo):
		hilo.dialogue_title = TITULO_PRIMER_HILO if alas_limpiadas == 1 else TITULO_SEGUNDO_HILO
		hilo.reveal()


func _al_completar_jarron_boss(restaurando: bool) -> void:
	if boss_derrotado:
		return

	jarrones_boss_completados += 1
	if not restaurando:
		_reir(1.0, SONIDOS_JARRONES_ELIAN[jarrones_boss_completados - 1])
		_decir_como_archivero(TITULOS_ARCHIVERO[jarrones_boss_completados - 1])
	if jarrones_boss_completados < JARRONES_BOSS.size():
		return

	boss_derrotado = true
	get_tree().call_group(GRUPO_PROYECTILES, "remove")
	$ScreenOverlay.visible = false
	if is_instance_valid(pesadilla):
		pesadilla.intensidad_fija = 0.0
	if is_instance_valid(elian):
		AnimacionDeElian.quedarse_en_reposo(elian)
	if not restaurando:
		_sacudir_pantalla()

	_quitar([bloqueo_puente])
	if is_instance_valid(puente_boss_final):
		if restaurando:
			puente_boss_final.enabled = true
		else:
			Retejido.tejer_por_franjas(puente_boss_final)
	if is_instance_valid(hilo_central):
		hilo_central.reveal()


func _on_trigger_central_body_entered(body: Node2D) -> void:
	if not body.is_in_group(GRUPO_JUGADOR) or risa_central_sonada:
		return
	risa_central_sonada = true
	if acercamiento_elian_visto or not is_instance_valid(elian):
		_reir()
		efectos.invocar_vacio()
		return
	acercamiento_elian_visto = true
	golpes.protegido = true
	# En la animación de ver a Elián el HUD se desvanece.
	ReglaHilosHud.ocultar_en_animacion(true)
	await efectos.acercamiento_a_elian(jugador, elian, _reir, _decir_como_archivero)
	ReglaHilosHud.ocultar_en_animacion(false)
	golpes.protegido = false
