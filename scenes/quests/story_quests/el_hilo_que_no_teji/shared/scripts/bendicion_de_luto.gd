# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node
## La bendición de Luto: tras el primer deshilado, Luto aparece como fantasma y se queda junto a
## Lino. Mientras esté con él, los proyectiles que se le acercan dentro de su zona van más
## despacio y se tiñen de azul. Termina cuando Lázaro lo llama, antes de la sala de Elián.

const AyudasDeEscena = preload("ayudas_de_escena.gd")
const LutoFantasma = preload("luto_fantasma.gd")
const ProteccionDeLuto = preload("proteccion_de_luto.gd")

const MUERTES_PARA_LA_BENDICION: int = 1
const TITULO_DIALOGO: String = "bendicion_de_luto"
const TITULO_DESPEDIDA: String = "luto_se_va"
## dialogos_bendiciones.dialogue
const DIALOGO: DialogueResource = preload("../dialogues/dialogos_bendiciones.dialogue")
const TITULO_PENSAMIENTO_DE_LINO: String = "pensamiento_luto"
const RUTA_GLOBO_DE_LINO: NodePath = ^"HUD/PanelContainer"
const LUGARES_PARA_LUTO: Array[Vector2] = [
	Vector2(-80, 0),
	Vector2(80, 0),
	Vector2(-70, 45),
	Vector2(70, 45),
	Vector2(0, 75),
	Vector2(-110, -15),
	Vector2(110, -15),
]
# Capa de colisión 512: solo Lino la tiene en su máscara (son las orillas del lago)
const CAPAS_DE_PARED: int = 1 | 16 | 512
const RADIO_DE_LUTO: float = 22.0
const LADRIDOS_AL_LLEGAR: int = 3
const MAXIMO_DE_LADRIDOS: int = 1
const PAUSA_ENTRE_LADRIDOS: float = 0.38
const ESPERA_INICIAL: float = 1.5
## Pausa tras la llamada de Lázaro antes de que Luto reaccione.
const PAUSA_ANTES_DE_RESPONDER: float = 0.5
const PAUSA_ANTES_DE_IRSE: float = 0.4

## Hasta dónde llega la protección de Luto, y cuánto frena: no se detienen, solo se arrastran.
const DISTANCIA_DE_FRENADO: float = 130.0
const VELOCIDAD_AL_FRENAR: float = 0.4
const TIEMPO_DE_FRENADO: float = 0.35
const GRUPO_PROYECTILES: StringName = &"projectiles"
const META_VELOCIDAD: StringName = &"velocidad_antes_de_luto"
const META_HALO: StringName = &"halo_de_luto"

## Un proyectil frenado se tiñe de azul y lleva un pequeño halo, para ver quién lo frena.
const TINTE_DEL_PROYECTIL := Color(0.62, 0.82, 1.0, 1.0)
const BRILLO_DEL_HALO_DEL_PROYECTIL: float = 0.55
const ESCALA_DEL_HALO_DEL_PROYECTIL := Vector2(0.9, 0.9)
const TAMANO_TEXTURA_HALO: int = 64
const DURACION_DEL_TINTE: float = 0.3

# Por nivel: en qué partida (numero_partida) se anunció o se fue Luto. Así no se repite al
# reintentar el nivel, pero sí en otra partida, y lo de un nivel no cuenta en el otro.
static var _anunciada_en: Dictionary = {}
static var _despedida_en: Dictionary = {}
# Luto no se queda en un nivel: acompaña a Lino de un nivel al siguiente hasta que Lázaro lo
# llama. Aquí se guarda en qué partida apareció por primera vez y en cuál se fue.
static var _partida_con_luto: int = -1
static var _partida_sin_luto: int = -1

var jugador: Node2D
## Nombre con el que este nivel cuenta sus muertes en ElHiloQueNoTejiState.
var nivel: String

var _en_dialogo: bool = false
var _espera: float = ESPERA_INICIAL
var _activa: bool = false
var _luto: LutoFantasma
var _proteccion: ProteccionDeLuto
var _halo_de_proyectil: GradientTexture2D
var _suma: CanvasItemMaterial


## Si Luto va a aparecer justo ahora, al reaparecer tras la primera muerte del nivel.
static func aparece_al_reaparecer(nivel_a_mirar: String) -> bool:
	if _viene_con_lino_desde_antes():
		return false
	if _anunciada_en.get(nivel_a_mirar, -1) == ElHiloQueNoTejiState.numero_partida:
		return false
	return ElHiloQueNoTejiState.muertes_en(nivel_a_mirar) == MUERTES_PARA_LA_BENDICION


## Luto ya apareció en un nivel anterior de esta partida y sigue con Lino.
static func _viene_con_lino_desde_antes() -> bool:
	var partida: int = ElHiloQueNoTejiState.numero_partida
	return _partida_con_luto == partida and _partida_sin_luto != partida


func _ready() -> void:
	var viene_de_antes: bool = _viene_con_lino_desde_antes()
	var hay_muertes: bool = ElHiloQueNoTejiState.muertes_en(nivel) >= MUERTES_PARA_LA_BENDICION
	if not (hay_muertes or viene_de_antes) or _ya_se_fue():
		set_process(false)
		set_physics_process(false)
		return
	if DialogueManager.has_signal("dialogue_started"):
		DialogueManager.dialogue_started.connect(
			func(_recurso: Resource) -> void: _en_dialogo = true
		)
	DialogueManager.dialogue_ended.connect(func(_recurso: Resource) -> void: _en_dialogo = false)
	_halo_de_proyectil = AyudasDeEscena.textura_de_halo(TAMANO_TEXTURA_HALO)
	_suma = AyudasDeEscena.material_de_suma()
	# Al reintentar el nivel o al venir del anterior no se vuelve a anunciar: Luto ya está con Lino.
	if viene_de_antes and not _ya_se_anuncio():
		_anunciada_en[nivel] = ElHiloQueNoTejiState.numero_partida
	if _ya_se_anuncio():
		_acompanar_a_lino.call_deferred(false)


func _process(delta: float) -> void:
	if _ya_se_anuncio():
		set_process(false)
		return
	_espera -= delta
	if _espera > 0.0 or _en_dialogo or not is_instance_valid(jugador):
		return
	if jugador.get("mode") != Player.Mode.USER_CONTROLLED:
		return
	_anunciada_en[nivel] = ElHiloQueNoTejiState.numero_partida
	_partida_con_luto = ElHiloQueNoTejiState.numero_partida
	set_process(false)
	_anunciar()


func _physics_process(delta: float) -> void:
	if not _activa or not is_instance_valid(jugador):
		return
	var frenando: int = 0
	for proyectil in get_tree().get_nodes_in_group(GRUPO_PROYECTILES):
		var cuerpo := proyectil as RigidBody2D
		if not cuerpo:
			continue
		# azul mientras esté dentro de la zona, venga o se aleje; solo frena el que se acerca
		var dentro: bool = (
			jugador.global_position.distance_to(cuerpo.global_position) <= DISTANCIA_DE_FRENADO
		)
		if dentro:
			_frenar(cuerpo, delta)
			frenando += 1
		_marcar(cuerpo, dentro, delta)
	if is_instance_valid(_proteccion):
		_proteccion.frenando(frenando)


## Lázaro llama a Luto y este se va con él. Hay que esperarla: Lino no recupera el control
## hasta que Luto ha desaparecido, para que no se cruce con la entrada a la sala de Elián.
func despedirse() -> void:
	if not _activa:
		return
	_activa = false
	_despedida_en[nivel] = ElHiloQueNoTejiState.numero_partida
	_partida_sin_luto = ElHiloQueNoTejiState.numero_partida
	_soltar_proyectiles()

	await AyudasDeEscena.mostrar_globo_arriba(DIALOGO, TITULO_DESPEDIDA)
	if _en_dialogo:
		await DialogueManager.dialogue_ended
	await get_tree().create_timer(PAUSA_ANTES_DE_RESPONDER).timeout

	if is_instance_valid(_luto):
		await _luto.ladrar(1, PAUSA_ANTES_DE_IRSE, MAXIMO_DE_LADRIDOS)
	if is_instance_valid(_proteccion):
		_proteccion.desvanecer()
	if is_instance_valid(_luto):
		await _luto.irse(Vector2.DOWN)


func _ya_se_anuncio() -> bool:
	return _anunciada_en.get(nivel, -1) == ElHiloQueNoTejiState.numero_partida


func _ya_se_fue() -> bool:
	return _despedida_en.get(nivel, -1) == ElHiloQueNoTejiState.numero_partida


func _anunciar() -> void:
	_acompanar_a_lino(true)
	await AyudasDeEscena.mostrar_globo_arriba(DIALOGO, TITULO_DIALOGO)
	if is_instance_valid(_luto):
		await _luto.ladrar(LADRIDOS_AL_LLEGAR, PAUSA_ENTRE_LADRIDOS, MAXIMO_DE_LADRIDOS)
	if _en_dialogo:
		await DialogueManager.dialogue_ended
	if not is_instance_valid(jugador) or not jugador.owner:
		return
	var globo_de_lino := jugador.owner.get_node_or_null(RUTA_GLOBO_DE_LINO)
	var pensamiento: DialogueLine = await DIALOGO.get_next_dialogue_line(TITULO_PENSAMIENTO_DE_LINO)
	if (
		pensamiento
		and is_instance_valid(globo_de_lino)
		and globo_de_lino.has_method("mostrar_pensamiento")
	):
		globo_de_lino.mostrar_pensamiento(pensamiento.text)


## Luto aparece junto a Lino y empieza la protección. Desde aquí frena los proyectiles.
func _acompanar_a_lino(con_motas: bool) -> void:
	if _activa or not is_instance_valid(jugador):
		return
	_activa = true
	_crear_proteccion(con_motas)
	_crear_luto()


func _crear_proteccion(con_motas: bool) -> void:
	_proteccion = ProteccionDeLuto.new()
	_proteccion.radio = DISTANCIA_DE_FRENADO
	jugador.add_child(_proteccion)
	if con_motas:
		_proteccion.soltar_motas()


func _crear_luto() -> void:
	var luto := LutoFantasma.new()
	luto.jugador = jugador
	luto.z_index = jugador.z_index
	jugador.get_parent().add_child(luto)
	luto.colocar_en(_lugar_libre_junto_a_lino())
	_luto = luto


func _lugar_libre_junto_a_lino() -> Vector2:
	var espacio := jugador.get_world_2d().direct_space_state
	var pies := CircleShape2D.new()
	pies.radius = RADIO_DE_LUTO
	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = pies
	consulta.collision_mask = CAPAS_DE_PARED
	for desplazamiento in LUGARES_PARA_LUTO:
		var lugar := jugador.global_position + desplazamiento
		consulta.transform = Transform2D(0.0, lugar)
		if not espacio.intersect_shape(consulta, 1).is_empty():
			continue
		var rayo := PhysicsRayQueryParameters2D.create(
			jugador.global_position, lugar, CAPAS_DE_PARED
		)
		if jugador is CollisionObject2D:
			rayo.exclude = [(jugador as CollisionObject2D).get_rid()]
		if espacio.intersect_ray(rayo).is_empty():
			return lugar
	return jugador.global_position + LUGARES_PARA_LUTO[0]


## Frena el proyectil que viene hacia Lino y alarga su vida lo que pierde por ir más despacio,
## para que llegue tan lejos como habría llegado sin frenar.
func _frenar(cuerpo: RigidBody2D, delta: float) -> void:
	var hacia_lino: Vector2 = jugador.global_position - cuerpo.global_position
	var velocidad: Vector2 = cuerpo.linear_velocity
	# Solo los que vienen hacia Lino: los que él repele se van a su velocidad.
	if velocidad.dot(hacia_lino) <= 0.0:
		return
	var normal: float = maxf(cuerpo.get_meta(META_VELOCIDAD, 0.0), velocidad.length())
	cuerpo.set_meta(META_VELOCIDAD, normal)
	var frenada: float = normal * VELOCIDAD_AL_FRENAR
	if velocidad.length() > frenada:
		var paso: float = (normal - frenada) * delta / TIEMPO_DE_FRENADO
		cuerpo.linear_velocity = velocidad.normalized() * maxf(velocidad.length() - paso, frenada)
	_compensar_la_duracion(cuerpo, normal, delta)


## Suma a la vida del proyectil el tiempo que deja de recorrer por ir más despacio.
func _compensar_la_duracion(cuerpo: RigidBody2D, normal: float, delta: float) -> void:
	var temporizador: Variant = cuerpo.get("duration_timer")
	if not temporizador is Timer or normal <= 0.0:
		return
	var reloj := temporizador as Timer
	var perdido: float = 1.0 - clampf(cuerpo.linear_velocity.length() / normal, 0.0, 1.0)
	if perdido <= 0.0 or reloj.is_stopped():
		return
	# start() cambia el tiempo de espera para siempre: se devuelve el original
	var original: float = reloj.wait_time
	reloj.start(reloj.time_left + perdido * delta)
	reloj.wait_time = original


## Tiñe el proyectil y le pone un halo mientras lo frena, y se los quita al soltarlo.
func _marcar(cuerpo: RigidBody2D, afectado: bool, delta: float) -> void:
	var guardado: Variant = cuerpo.get_meta(META_HALO) if cuerpo.has_meta(META_HALO) else null
	var halo: Sprite2D = guardado as Sprite2D if is_instance_valid(guardado) else null
	if not halo:
		if not afectado:
			return
		halo = _crear_halo_de_proyectil(cuerpo)
	var fuerza: float = halo.modulate.a / BRILLO_DEL_HALO_DEL_PROYECTIL
	fuerza = move_toward(fuerza, 1.0 if afectado else 0.0, delta / DURACION_DEL_TINTE)
	halo.modulate.a = fuerza * BRILLO_DEL_HALO_DEL_PROYECTIL
	var cosas: Variant = cuerpo.get("visible_things")
	if cosas is Node2D:
		(cosas as Node2D).modulate = Color.WHITE.lerp(TINTE_DEL_PROYECTIL, fuerza)


func _crear_halo_de_proyectil(cuerpo: RigidBody2D) -> Sprite2D:
	var halo := Sprite2D.new()
	halo.texture = _halo_de_proyectil
	halo.material = _suma
	halo.scale = ESCALA_DEL_HALO_DEL_PROYECTIL
	halo.modulate = Color(TINTE_DEL_PROYECTIL, 0.0)
	cuerpo.add_child(halo)
	cuerpo.set_meta(META_HALO, halo)
	return halo


## Al irse Luto, los proyectiles recuperan su color de golpe.
func _soltar_proyectiles() -> void:
	for proyectil in get_tree().get_nodes_in_group(GRUPO_PROYECTILES):
		if proyectil.has_meta(META_HALO):
			var halo: Variant = proyectil.get_meta(META_HALO)
			if is_instance_valid(halo):
				(halo as Node).queue_free()
			proyectil.remove_meta(META_HALO)
		var cosas: Variant = proyectil.get("visible_things")
		if cosas is Node2D:
			(cosas as Node2D).modulate = Color.WHITE
