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
## Cada sombra puede volver a disparar pasado este tiempo. El nivel decide cuándo dispara
## cada una (ver _dirigir_sombras), así que esto solo fija el período del temporizador.
const SEGUNDOS_ENTRE_DISPAROS: float = 8.0
const Z_PROYECTILES: int = 20
## El proyectil base dura 5 s; aquí dura más porque es el nivel de aprendizaje.
const DURACION_PROYECTIL: float = 9.0
const ID_FUENTE_ORILLA: int = 0
## Tutorial del empuje: al principio solo dispara la sombra de este jarrón, y el primer
## proyectil no hace daño. Las demás sombras empiezan al llenarlo.
const JARRON_DEL_TUTORIAL: String = "FillingBarrel"
const SOMBRA_DEL_TUTORIAL: String = "ThrowingEnemy"
## Pensamientos de Lino durante el tutorial. Nunca salen con un diálogo abierto ni uno encima de
## otro. "Devuelto" y "golpe" salen una sola vez por partida; "inactivo" se repite mientras Lino
## no llene ningún jarrón. Si coinciden varios gana el más importante y los demás esperan su turno.
const CLAVE_DEVUELTO: String = "devuelto"
const CLAVE_GOLPE: String = "golpe"
const CLAVE_INACTIVO: String = "inactivo"
## Título de cada pensamiento en el .dialogue del nivel.
const TITULO_DEL_PENSAMIENTO: Dictionary[String, String] = {
	CLAVE_DEVUELTO: "pensamiento_devuelto",
	CLAVE_GOLPE: "pensamiento_golpe",
	CLAVE_INACTIVO: "pensamiento_inactivo",
}
## Mayor número, más prioridad: lo que descubre (devolverlo) pesa más que lo que le pasa
## (golpe), y esto más que el recordatorio por no hacer nada.
const PRIORIDAD_DEL_PENSAMIENTO: Dictionary[String, int] = {
	CLAVE_DEVUELTO: 3,
	CLAVE_GOLPE: 2,
	CLAVE_INACTIVO: 1,
}
## Respiro mínimo entre el inicio de un pensamiento y el siguiente.
const SEGUNDOS_ENTRE_PENSAMIENTOS: float = 5.0
## Un pensamiento más importante puede reemplazar al que se está mostrando, pero solo cuando
## este ya tuvo tiempo de leerse.
const SEGUNDOS_MINIMOS_DE_LECTURA: float = 2.5
## Un pensamiento que no pudo salir porque había otro se guarda este tiempo y luego se descarta,
## porque ya no tendría sentido (por ejemplo, un golpe de hace medio minuto).
const SEGUNDOS_DE_VIGENCIA: float = 12.0
## Sin llenar ningún jarrón: la primera frase sale a los 20 s y las siguientes cada 30 s.
const SEGUNDOS_HASTA_LA_PRIMERA_INACTIVIDAD: float = 20.0
const SEGUNDOS_ENTRE_INACTIVIDADES: float = 30.0
## Sin llenar nada durante este tiempo, Lázaro concede su bendición (la guía de empuje).
const SEGUNDOS_PARA_LA_BENDICION: float = 30.0
## Lino repele un proyectil cuando su rumbo cambia mucho estando cerca de él justo después de
## pulsar repeler. Si el nuevo rumbo apunta hacia una sombra, lo está devolviendo.
const ALCANCE_DEL_EMPUJE: float = 220.0
const CAMBIO_DE_RUMBO: float = 0.3
const VENTANA_DE_REPELER: float = 0.8
const UMBRAL_DE_DEVOLUCION: float = 0.6
const RUTA_CARTEL: String = "OnTheGround/CartelZ"
## Segundos con Lino ya abajo y sin diálogo antes de que la sombra del tutorial dispare sola.
const ESPERA_TRAS_BAJAR: float = 8.0
## Tope absoluto desde que carga el nivel, por si la bajada o un diálogo no avisan.
const ESPERA_ABSOLUTA: float = 25.0
## Pausa tras acercarse al cartel antes del primer disparo.
const PAUSA_TRAS_LEER_EL_CARTEL: float = 2.0
## Cada sombra dispara cada tanto, y solo las que están cerca de Lino. Entre dos sombras
## distintas hay una pequeña separación para que no disparen a la vez.
const PAUSA_ENTRE_DISPAROS: float = 7.0
const SEPARACION_ENTRE_SOMBRAS: float = 2.5
const DISTANCIA_DE_ATAQUE: float = 1300.0
const MAXIMO_VIVOS: int = 4
const DELAY_DEL_DISPARO: float = 0.05

# static para que los jarrones llenos sobrevivan al recargar la escena tras morir
static var jarrones_guardados: Array[String] = []
# Pensamientos ya dichos en cada partida (clave → número de partida); no se repiten al recargar
static var _pensamientos_dichos: Dictionary = {}

@export var orbes_por_jarron: int = 2

var jarrones_llenos: int = 0
var orillas: TileMapLayer
var puentes_tejidos: Array[TileMapLayer] = []
var flecha: FlechaDeEmpuje
var bendicion: BendicionDeLazaro
var bendicion_de_luto: BendicionDeLuto
var _primer_proyectil_visto: bool = false
var _disparo_abierto: bool = false
var _leyo_el_cartel: bool = false
var _lino_ya_bajo: bool = false
var _golpes: GolpesALino
var _hay_proyectiles: bool = false
var _segundos_sin_llenar: float = 0.0
var _proxima_inactividad: float = SEGUNDOS_HASTA_LA_PRIMERA_INACTIVIDAD
var _segundos_desde_el_ultimo_pensamiento: float = INF
## Pensamientos esperando turno: clave → cuándo caducan
var _pensamientos_en_espera: Dictionary = {}
## Texto de cada pensamiento, leído del .dialogue al empezar el nivel: clave → texto
var _frases: Dictionary = {}
## Prioridad del pensamiento de este nivel que está en pantalla (0 si no hay ninguno nuestro).
var _prioridad_en_pantalla: int = 0
var _tiempo_en_nivel: float = 0.0
var _en_dialogo: bool = false
var _espera_libre: float = 0.0
var _espera_tras_leer: float = 0.0
var _pausa: float = 0.0
var _velocidades: Dictionary = {}
var _ultimo_repeler: float = -INF
var _ultimo_disparo: Dictionary = {}

@onready var jugador: Player = $OnTheGround/Player
@onready var capas: Node2D = $TileMapLayers
@onready var panel_pensamiento: Control = get_node_or_null("HUD/PanelContainer")


func _ready() -> void:
	_cargar_los_pensamientos()
	_golpes = GolpesALino.new(jugador, panel_pensamiento)
	add_child(_golpes)
	# en este nivel el primer golpe lo dice el tutorial, no la frase de la culpa ajena
	_golpes.frase_primer_golpe = ""
	_golpes.golpe_inofensivo.connect(_al_golpe)
	_golpes.golpe_con_dano.connect(_al_golpe)
	var repeler := jugador.get_node_or_null("PlayerRepel")
	if repeler:
		repeler.repelling_changed.connect(_al_repeler)
	if ElHiloQueNoTejiState.es_partida_nueva_para(scene_file_path):
		jarrones_guardados.clear()
	child_entered_tree.connect(_subir_proyectil)

	_configurar_sombras()
	_tomar_el_control_de_las_sombras()
	_vigilar_el_cartel_y_los_dialogos()
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
	cuerda.bajada_terminada.connect(func() -> void: _lino_ya_bajo = true)
	add_child(cuerda)
	var reaparicion := ReaparicionEnHilo.new()
	reaparicion.omitir_frase = _aparece_luto_al_reaparecer
	add_child(reaparicion)


## La guía no está desde el principio: Lázaro la concede si Lino pasa 30 segundos sin llenar un
## jarrón, y entonces vale hasta el final de la partida. Luto aparece tras la primera muerte y
## acompaña a Lino hasta que Lázaro lo llama, ya en el 3.2.
func _preparar_bendiciones() -> void:
	if jarrones_llenos >= PUENTE_DE_CADA_JARRON.size():
		return
	flecha = FlechaDeEmpuje.new()
	flecha.jugador = jugador
	for nombre in PUENTE_DE_CADA_JARRON:
		flecha.jarrones.append(get_node_or_null(RUTA_OBJETOS + nombre))
	add_child(flecha)
	bendicion = BendicionDeLazaro.new()
	bendicion.jugador = jugador
	bendicion.nivel = scene_file_path
	bendicion.flecha = flecha
	bendicion.cuenta_propia = false
	add_child(bendicion)
	bendicion_de_luto = BendicionDeLuto.new()
	bendicion_de_luto.jugador = jugador
	bendicion_de_luto.nivel = scene_file_path
	add_child(bendicion_de_luto)


## La primera vez que Luto aparece, su llegada ya acompaña a Lino: no se suma la frase de siempre.
func _aparece_luto_al_reaparecer() -> bool:
	var quedan_jarrones: bool = jarrones_llenos < PUENTE_DE_CADA_JARRON.size()
	return quedan_jarrones and BendicionDeLuto.aparece_al_reaparecer(scene_file_path)


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
		sombra.projectile_duration = DURACION_PROYECTIL


func _conectar_jarrones() -> void:
	for nombre in PUENTE_DE_CADA_JARRON:
		var jarron := get_node_or_null(RUTA_OBJETOS + nombre) as FillingBarrel
		if jarron:
			jarron.needed_amount = orbes_por_jarron
			jarron.completed.connect(_al_llenar_jarron.bind(nombre))
			# acertar un proyectil en el jarrón ya es avanzar, aunque todavía no se llene
			if jarron.has_signal("orbe_recibido"):
				jarron.connect("orbe_recibido", _reiniciar_inactividad)


func _mostrar_puentes_rotos() -> void:
	for nombre in PUENTE_DE_CADA_JARRON:
		var roto := _puente_roto(nombre)
		var reparado := _puente_reparado(nombre)
		if roto:
			roto.show()
			roto.enabled = true
		if reparado:
			reparado.enabled = false


## Lee del .dialogue el texto de cada pensamiento, para no tenerlo escrito en el código.
func _cargar_los_pensamientos() -> void:
	for clave: String in TITULO_DEL_PENSAMIENTO:
		var linea: DialogueLine = await DIALOGO.get_next_dialogue_line(
			TITULO_DEL_PENSAMIENTO[clave]
		)
		if linea:
			_frases[clave] = linea.text


func _process(delta: float) -> void:
	_segundos_desde_el_ultimo_pensamiento += delta
	# el reloj de inactividad corre desde que sale el primer proyectil y solo se detiene
	# con un diálogo abierto; únicamente llenar un jarrón lo reinicia
	if _primer_proyectil_visto and not _en_dialogo:
		_segundos_sin_llenar += delta
	if (
		is_instance_valid(bendicion)
		and _segundos_sin_llenar >= SEGUNDOS_PARA_LA_BENDICION
		and _nivel_en_curso()
	):
		bendicion.conceder()
	_atender_pensamientos()
	_dirigir_sombras(delta)


## Pide un pensamiento de Lino. Si no puede salir ahora se guarda un rato y sale en cuanto
## toque, sin pisar a otro más importante.
func _pensar(clave: String) -> void:
	if not _nivel_en_curso() or not is_instance_valid(panel_pensamiento):
		return
	if _pensamientos_dichos.get(clave, -1) == ElHiloQueNoTejiState.numero_partida:
		return
	if _pensamientos_en_espera.has(clave):
		return
	_pensamientos_en_espera[clave] = Time.get_ticks_msec() / 1000.0 + SEGUNDOS_DE_VIGENCIA


## Elige entre lo que está esperando (y el recordatorio por inactividad) y lo muestra si toca.
func _atender_pensamientos() -> void:
	if not _nivel_en_curso() or not is_instance_valid(panel_pensamiento) or _en_dialogo:
		return
	if not panel_pensamiento.visible:
		_prioridad_en_pantalla = 0

	var ahora: float = Time.get_ticks_msec() / 1000.0
	var elegido: String = ""
	for clave: String in _pensamientos_en_espera.keys():
		if _pensamientos_en_espera[clave] < ahora:
			_pensamientos_en_espera.erase(clave)
			continue
		if elegido == "" or PRIORIDAD_DEL_PENSAMIENTO[clave] > PRIORIDAD_DEL_PENSAMIENTO[elegido]:
			elegido = clave
	# el recordatorio no se guarda: si hay algo más importante o no hay hueco, vuelve a intentarlo
	if elegido == "" and _segundos_sin_llenar >= _proxima_inactividad:
		elegido = CLAVE_INACTIVO
	if elegido == "" or not _frases.has(elegido):
		return

	if panel_pensamiento.visible:
		# solo reemplaza al que se está leyendo uno más importante, y cuando ya tuvo su tiempo
		if _prioridad_en_pantalla == 0:
			return
		if PRIORIDAD_DEL_PENSAMIENTO[elegido] <= _prioridad_en_pantalla:
			return
		if _segundos_desde_el_ultimo_pensamiento < SEGUNDOS_MINIMOS_DE_LECTURA:
			return
	elif _segundos_desde_el_ultimo_pensamiento < SEGUNDOS_ENTRE_PENSAMIENTOS:
		return

	_pensamientos_en_espera.erase(elegido)
	if elegido == CLAVE_INACTIVO:
		_proxima_inactividad = _segundos_sin_llenar + SEGUNDOS_ENTRE_INACTIVIDADES
	else:
		_pensamientos_dichos[elegido] = ElHiloQueNoTejiState.numero_partida
	if elegido == CLAVE_DEVUELTO:
		# descubrir la idea cierra el ciclo: los otros dos vuelven a empezar de cero, y si el
		# siguiente proyectil lo golpea podrá leer su frase de nuevo
		_pensamientos_dichos.erase(CLAVE_GOLPE)
		_pensamientos_en_espera.clear()
		_reiniciar_inactividad()
	_prioridad_en_pantalla = PRIORIDAD_DEL_PENSAMIENTO[elegido]
	_segundos_desde_el_ultimo_pensamiento = 0.0
	panel_pensamiento.mostrar_pensamiento(_frases[elegido])


func _reiniciar_inactividad() -> void:
	_segundos_sin_llenar = 0.0
	_proxima_inactividad = SEGUNDOS_HASTA_LA_PRIMERA_INACTIVIDAD


func _al_golpe() -> void:
	_pensar(CLAVE_GOLPE)


func _al_repeler(repeliendo: bool) -> void:
	if repeliendo:
		_ultimo_repeler = Time.get_ticks_msec() / 1000.0


func _physics_process(_delta: float) -> void:
	if not _nivel_en_curso():
		return
	var ahora: float = Time.get_ticks_msec() / 1000.0
	var hace_poco_repelio: bool = ahora - _ultimo_repeler < VENTANA_DE_REPELER
	var actuales: Dictionary = {}
	for proyectil in _proyectiles_vivos():
		var cuerpo := proyectil as RigidBody2D
		if not cuerpo:
			continue
		var id := cuerpo.get_instance_id()
		var antes: Vector2 = _velocidades.get(id, Vector2.ZERO)
		var ahora_v: Vector2 = cuerpo.linear_velocity
		# al repelerlo la velocidad pasa un cuadro por cero: se conserva la última válida
		actuales[id] = ahora_v if ahora_v.length() > 1.0 else antes
		if not hace_poco_repelio or antes.length() <= 1.0 or ahora_v.length() <= 1.0:
			continue
		var cerca: bool = (
			jugador.global_position.distance_to(cuerpo.global_position) < ALCANCE_DEL_EMPUJE
		)
		if cerca and antes.normalized().dot(ahora_v.normalized()) < CAMBIO_DE_RUMBO:
			_al_ser_repelido(cuerpo)
			_ultimo_repeler = -INF
	_velocidades = actuales


## Mira, por la posición de las sombras, si el proyectil repelido va de vuelta hacia ellas.
func _al_ser_repelido(cuerpo: RigidBody2D) -> void:
	var rumbo := cuerpo.linear_velocity.normalized()
	for sombra in _sombras():
		var hacia: Vector2 = cuerpo.global_position.direction_to(sombra.global_position)
		if rumbo.dot(hacia) > UMBRAL_DE_DEVOLUCION:
			_pensar(CLAVE_DEVUELTO)
			return


## El nivel entero es un tutorial: los pensamientos valen hasta que se llenen todos los jarrones.
func _nivel_en_curso() -> bool:
	return jarrones_guardados.size() < PUENTE_DE_CADA_JARRON.size()


func _en_tutorial() -> bool:
	return not jarrones_guardados.has(JARRON_DEL_TUTORIAL)


## Las sombras dejan de disparar solas: el nivel decide cuándo y cuántos proyectiles hay.
func _tomar_el_control_de_las_sombras() -> void:
	for sombra in _sombras():
		if is_instance_valid(sombra.timer):
			sombra.timer.one_shot = true
			sombra.timer.stop()
	_disparo_abierto = not _en_tutorial()


func _vigilar_el_cartel_y_los_dialogos() -> void:
	var cartel := get_node_or_null(RUTA_CARTEL)
	var zona: Area2D = null
	if cartel:
		zona = cartel.get_node_or_null("Area2D") as Area2D
	if zona:
		zona.body_entered.connect(
			func(cuerpo: Node2D) -> void:
				if cuerpo == jugador:
					_leyo_el_cartel = true
		)
	if DialogueManager.has_signal("dialogue_started"):
		DialogueManager.dialogue_started.connect(
			func(_recurso: Resource) -> void: _en_dialogo = true
		)
	DialogueManager.dialogue_ended.connect(func(_recurso: Resource) -> void: _en_dialogo = false)


func _proyectiles_vivos() -> Array[Node2D]:
	var vivos: Array[Node2D] = []
	for nodo in get_tree().get_nodes_in_group(GRUPO_PROYECTILES):
		var proyectil := nodo as Node2D
		if proyectil and not proyectil.is_queued_for_deletion():
			if proyectil.has_meta(FlechaDeEmpuje.META_CON_FLECHA):
				vivos.append(proyectil)
	return vivos


func _dirigir_sombras(delta: float) -> void:
	_pausa = maxf(_pausa - delta, 0.0)
	_tiempo_en_nivel += delta
	var vivos := _proyectiles_vivos().size()
	_hay_proyectiles = vivos > 0
	if not _disparo_abierto:
		_esperar_el_primer_disparo(delta)
		return

	if _pausa > 0.0 or vivos >= MAXIMO_VIVOS:
		return
	var sombra := _sombra_que_dispara()
	if sombra:
		_ultimo_disparo[sombra] = Time.get_ticks_msec() / 1000.0
		_pausa = SEPARACION_ENTRE_SOMBRAS
		sombra.timer.start(DELAY_DEL_DISPARO)


## El primer disparo espera a que Lino esté abajo y haya tenido un momento para orientarse:
## unos segundos tras acercarse al cartel, o un máximo si no se acerca. Si algo no avisa
## (la bajada, un diálogo), un tope absoluto lo abre igual.
func _esperar_el_primer_disparo(delta: float) -> void:
	if _en_dialogo:
		return
	if _lino_ya_bajo:
		_espera_libre += delta
	if _leyo_el_cartel:
		_espera_tras_leer += delta
	if (
		_espera_libre >= ESPERA_TRAS_BAJAR
		or _espera_tras_leer >= PAUSA_TRAS_LEER_EL_CARTEL
		or _tiempo_en_nivel >= ESPERA_ABSOLUTA
	):
		_disparo_abierto = true


## Entre las sombras cercanas a Lino que ya pueden volver a disparar, la que lleva más sin hacerlo.
func _sombra_que_dispara() -> Node:
	var ahora: float = Time.get_ticks_msec() / 1000.0
	var elegida: Node = null
	var mas_antiguo: float = INF
	for sombra in _sombras():
		if not is_instance_valid(sombra.timer):
			continue
		if _en_tutorial() and sombra.name != SOMBRA_DEL_TUTORIAL:
			continue
		if jugador.global_position.distance_to(sombra.global_position) > DISTANCIA_DE_ATAQUE:
			continue
		var ultimo: float = _ultimo_disparo.get(sombra, -INF)
		if ahora - ultimo < PAUSA_ENTRE_DISPAROS:
			continue
		if ultimo < mas_antiguo:
			mas_antiguo = ultimo
			elegida = sombra
	return elegida


func _subir_proyectil(nodo: Node) -> void:
	if nodo is Node2D and nodo.is_in_group("projectiles"):
		nodo.z_index = maxi(nodo.z_index, Z_PROYECTILES)
		# Todos los proyectiles de esta sala los lanzan sombras, así que todos llevan flecha.
		nodo.set_meta(FlechaDeEmpuje.META_CON_FLECHA, true)
		if not _primer_proyectil_visto and not jarrones_guardados.has(JARRON_DEL_TUTORIAL):
			nodo.set_meta(GolpesALino.META_SIN_DANO, true)
		_primer_proyectil_visto = true


func _al_llenar_jarron(nombre: String) -> void:
	jarrones_llenos += 1
	jarrones_guardados.append(nombre)
	_reiniciar_inactividad()
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
	if flecha:
		flecha.activa = false
	_pensamientos_en_espera.clear()
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
