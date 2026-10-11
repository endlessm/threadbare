# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node
## El outro: Lino y Manchitas se reencuentran.

signal outro_finished

const FinalBordado = preload("final_bordado.gd")
## el_hilo_que_no_teji_outro.dialogue
const DIALOGO_OUTRO = preload("uid://b17brl3sdy2r6")
## after_the_tremor: dooropen.wav (el mismo de la intro).
const SONIDO_PUERTA = preload("uid://q0snt5ljuqha")
## manchitas_idle.png: Manchitas sentado moviendo la cola, sin collar.
const MANCHITAS_QUIETO: Texture2D = preload("uid://c5jwtwaipm002")
const CUADROS_QUIETO: int = 4
## lino_happy_cry.png: Lino sonríe con lágrimas y la mano tendida, ya sin el collar.
const LINO_LLORA_DE_ALEGRIA: Texture2D = preload("uid://1ut8qln3dkf8")
const CUADROS_LLORA_DE_ALEGRIA: int = 4
const TAMANO_CUADRO := Vector2(128, 192)
const VELOCIDAD_LENTA: float = 5.0
const VELOCIDAD_RAPIDA: float = 10.0
const DURACION_LADRIDO: float = 1.2
const DISTANCIA_MAXIMA_PUERTA: float = 5000.0
const ESCENA_SIGUIENTE: String = "res://scenes/world_map/frays_end.tscn"

const LINO_EN_EL_SOFA := Vector2(258, 225)
const LINO_DE_PIE := Vector2(256, 256)
const LINO_ANTE_LA_PUERTA := Vector2(440, 256)
const LINO_EN_EL_UMBRAL := Vector2(560, 256)
const MANCHITAS_EN_EL_CAMINO := Vector2(652, 272)
const MANCHITAS_AFUERA := Vector2(584, 272)
const VELOCIDAD_AL_CORRER: float = 120.0
const ESPERA_ANTES_DE_CORRER: float = 0.5
const LADRIDO_TRAS_LA_PALABRA: float = 1.0
## manchitas_run.png: 6 cuadros, mirando a la derecha y sin collar.
const MANCHITAS_CORRE: Texture2D = preload("uid://dyei2x6j4v41c")
const CUADROS_CORRER: int = 6
const PAUSA_ENTRE_LADRIDOS := Vector2(1.3, 2.2)
const LINO_JUNTO_A_MANCHITAS := Vector2(564, 256)

const PRIMER_LADRIDO: float = 2.0
const LINO_DESPIERTA: float = 4.0
const DURACION_LEVANTARSE: float = 0.5
const PAUSA_CONFUNDIDO: float = 1.5
const VELOCIDAD_AL_CAMINAR: float = 60.0
const PAUSA_ANTE_LA_PUERTA: float = 0.6
const PAUSA_TRAS_ABRIR: float = 0.8
const LLANTO_ANTES_DE_HABLAR: float = 2.5
const DURACION_ACERCARSE: float = 0.8
const PAUSA_ANTES_DEL_COLLAR: float = 0.6
const PAUSA_CON_EL_COLLAR: float = 1.2
const PAUSA_TRAS_EL_DIALOGO: float = 1.5
const VOLUMEN_LEJOS: float = -16.0
const VOLUMEN_CERCA: float = -3.0
const SUAVIDAD_DE_LA_CAMARA: float = 3.0
const DURACION_FUNDIDO_A_NEGRO: float = 1.5
const PAUSA_ANTES_DEL_TEXTO: float = 0.5
const PAUSA_TRAS_EL_TEXTO: float = 2.0

var _camara_siguiendo: bool = true
var _ladrando: bool = false
var _encuadrar_a_los_dos: bool = false

@onready var camara: Camera2D = $"../Camera2D"
@onready var lino: AnimatedSprite2D = $"../OnTheGround/Lino"
@onready var manchitas: AnimatedSprite2D = $"../OnTheGround/Manchitas"
@onready var puerta_abierta: TileMapLayer = $"../TileMapLayers/Door"
@onready var animaciones: AnimationPlayer = $"../OnTheGround/AnimationPlayer"
@onready var capa_de_pantalla: CanvasLayer = $"../ScreenOverlay"
@onready var fundido: ColorRect = $"../ScreenOverlay/ColorRect"
@onready var texto_final: RichTextLabel = $"../ScreenOverlay/ColorRect/RichTextLabel"


func _ready() -> void:
	outro_finished.connect(_on_outro_finished)
	# si no se detiene, el AnimationPlayer de la escena mueve a Lino y Manchitas por su cuenta
	if animaciones:
		animaciones.stop()
	lino.sprite_frames = _cuadros_de_lino()
	lino.show()
	lino.position = LINO_EN_EL_SOFA
	lino.flip_h = false
	lino.play(&"sleep")
	manchitas.show()
	manchitas.position = MANCHITAS_EN_EL_CAMINO
	manchitas.flip_h = true
	manchitas.sprite_frames = _cuadros_de_manchitas()
	manchitas.play(&"idle")
	puerta_abierta.hide()
	capa_de_pantalla.show()
	fundido.modulate.a = 0.0
	texto_final.visible_characters = 0
	camara.global_position = lino.global_position
	camara.make_current()
	_correr_secuencia.call_deferred()


func _process(delta: float) -> void:
	if _camara_siguiendo:
		var peso := 1.0 - exp(-SUAVIDAD_DE_LA_CAMARA * delta)
		var foco := lino.global_position
		if _encuadrar_a_los_dos:
			foco = (lino.global_position + manchitas.global_position) / 2.0
		camara.global_position = camara.global_position.lerp(foco, peso)


func _correr_secuencia() -> void:
	await _esperar(PRIMER_LADRIDO)
	_ladrar_sin_parar()
	await _esperar(LINO_DESPIERTA - PRIMER_LADRIDO)

	lino.play(&"c_confused")
	await _animar(lino, "position", LINO_DE_PIE, DURACION_LEVANTARSE)
	await _esperar(PAUSA_CONFUNDIDO)

	await _caminar_hasta(LINO_ANTE_LA_PUERTA)
	lino.play(&"c_idle")
	await _esperar(PAUSA_ANTE_LA_PUERTA)

	_sonar_puerta()
	puerta_abierta.show()
	_ladrando = false
	_encuadrar_a_los_dos = true
	_correr_hacia_lino()
	await _esperar(PAUSA_TRAS_ABRIR)
	await _caminar_hasta(LINO_EN_EL_UMBRAL)

	lino.play(&"cry")
	await _esperar(LLANTO_ANTES_DE_HABLAR)
	var bloqueo := BloqueoSaltoDialogo.new()
	add_child(bloqueo)
	DialogueManager.show_dialogue_balloon(DIALOGO_OUTRO, "start", [self])
	await DialogueManager.dialogue_ended
	bloqueo.queue_free()

	await _esperar(PAUSA_TRAS_EL_DIALOGO)
	lino.play(&"c_walk")
	await _animar(lino, "position", LINO_JUNTO_A_MANCHITAS, DURACION_ACERCARSE)
	lino.play(&"c_idle")
	await _esperar(PAUSA_ANTES_DEL_COLLAR)
	lino.play(&"happy_cry")
	_ladrar(0.0, true)
	await _esperar(DURACION_LADRIDO + PAUSA_CON_EL_COLLAR)

	_camara_siguiendo = false
	await _fundir_a_negro()
	outro_finished.emit()


func _caminar_hasta(destino: Vector2) -> void:
	lino.play(&"c_walk")
	lino.flip_h = destino.x < lino.position.x
	var duracion := lino.position.distance_to(destino) / VELOCIDAD_AL_CAMINAR
	var caminar := create_tween()
	caminar.tween_property(lino, "position", destino, duracion)
	await caminar.finished


func _fundir_a_negro() -> void:
	var bordado := FinalBordado.new()
	fundido.add_child(bordado)
	fundido.move_child(bordado, 0)
	var tween := create_tween()
	(
		tween
		. tween_property(fundido, "modulate:a", 1.0, DURACION_FUNDIDO_A_NEGRO)
		. set_trans(Tween.TRANS_SINE)
		. set_ease(Tween.EASE_OUT)
	)
	await tween.finished
	await _esperar(PAUSA_ANTES_DEL_TEXTO)
	await bordado.mostrar(texto_final)
	await _esperar(PAUSA_TRAS_EL_TEXTO)


# la llama el diálogo (lo recibe en [self])
func ladrar_despues_de_la_palabra() -> void:
	get_tree().create_timer(LADRIDO_TRAS_LA_PALABRA).timeout.connect(_ladrar.bind(0.0))


func _ladrar_sin_parar() -> void:
	_ladrando = true
	while _ladrando:
		var lejania := clampf(
			(
				lino.position.distance_to(LINO_ANTE_LA_PUERTA)
				/ LINO_DE_PIE.distance_to(LINO_ANTE_LA_PUERTA)
			),
			0.0,
			1.0
		)
		_ladrar(lerpf(VOLUMEN_CERCA, VOLUMEN_LEJOS, lejania))
		await _esperar(randf_range(PAUSA_ENTRE_LADRIDOS.x, PAUSA_ENTRE_LADRIDOS.y))


func _correr_hacia_lino() -> void:
	manchitas.play(&"idle")
	await _esperar(ESPERA_ANTES_DE_CORRER)
	manchitas.flip_h = true
	manchitas.play(&"run")
	var duracion := manchitas.position.distance_to(MANCHITAS_AFUERA) / VELOCIDAD_AL_CORRER
	var correr := create_tween()
	correr.tween_property(manchitas, "position", MANCHITAS_AFUERA, duracion)
	await correr.finished
	manchitas.play(&"idle")


func _ladrar(volumen: float, con_collar: bool = false) -> void:
	manchitas.play(&"bark" if con_collar else &"s_bark")
	get_tree().create_timer(DURACION_LADRIDO).timeout.connect(
		func() -> void:
			if con_collar:
				manchitas.pause()
				manchitas.frame = 0
			elif manchitas.animation == &"s_bark":
				manchitas.play(&"idle")
	)
	# Ladrido.sonar() no recibe volumen: se lo sumo a los reproductores que deja como hijos
	var antes := get_child_count()
	Ladrido.sonar(self, manchitas.global_position, 1)
	for i in range(antes, get_child_count()):
		var sonido := get_child(i) as AudioStreamPlayer2D
		if sonido:
			sonido.volume_db += volumen


func _cuadros_de_lino() -> SpriteFrames:
	var cuadros := lino.sprite_frames.duplicate() as SpriteFrames
	_agregar_animacion(
		cuadros, &"happy_cry", LINO_LLORA_DE_ALEGRIA, CUADROS_LLORA_DE_ALEGRIA, VELOCIDAD_LENTA
	)
	return cuadros


func _cuadros_de_manchitas() -> SpriteFrames:
	var cuadros := manchitas.sprite_frames.duplicate() as SpriteFrames
	_agregar_animacion(cuadros, &"idle", MANCHITAS_QUIETO, CUADROS_QUIETO, VELOCIDAD_LENTA)
	_agregar_animacion(cuadros, &"run", MANCHITAS_CORRE, CUADROS_CORRER, VELOCIDAD_RAPIDA)
	return cuadros


func _agregar_animacion(
	cuadros: SpriteFrames, nombre: StringName, tira: Texture2D, cantidad: int, velocidad: float
) -> void:
	if cuadros.has_animation(nombre):
		return
	cuadros.add_animation(nombre)
	cuadros.set_animation_speed(nombre, velocidad)
	cuadros.set_animation_loop(nombre, true)
	for i in cantidad:
		var cuadro := AtlasTexture.new()
		cuadro.atlas = tira
		cuadro.region = Rect2(Vector2(i * TAMANO_CUADRO.x, 0), TAMANO_CUADRO)
		cuadros.add_frame(nombre, cuadro)


func _sonar_puerta() -> void:
	var reproductor := AudioStreamPlayer2D.new()
	reproductor.stream = SONIDO_PUERTA
	reproductor.bus = &"SFX"
	reproductor.max_distance = DISTANCIA_MAXIMA_PUERTA
	add_child(reproductor)
	reproductor.global_position = puerta_abierta.to_global(
		puerta_abierta.map_to_local(puerta_abierta.get_used_cells()[0])
	)
	reproductor.finished.connect(reproductor.queue_free)
	reproductor.play()


func _animar(objeto: Object, propiedad: String, valor: Variant, duracion: float) -> void:
	var tween := create_tween()
	tween.tween_property(objeto, propiedad, valor, duracion).set_trans(Tween.TRANS_SINE).set_ease(
		Tween.EASE_IN_OUT
	)
	await tween.finished


func _esperar(segundos: float) -> void:
	await get_tree().create_timer(segundos).timeout


func _on_outro_finished() -> void:
	if ResourceLoader.exists(ESCENA_SIGUIENTE):
		get_tree().change_scene_to_file(ESCENA_SIGUIENTE)
	else:
		push_error("No se encontró la escena: ", ESCENA_SIGUIENTE)
