# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node
## Dirige la cinemática de apertura.
## Los tiempos son segundos dentro de la animación "intro_cinematic" del AnimationPlayer de Lino.

signal intro_finished

const PUERTA_ABRIENDOSE = preload("uid://q0snt5ljuqha")  # after_the_tremor: dooropen.wav
const SHADER_NIEBLA: Shader = preload("../../shared/shaders/niebla_del_deshilado.gdshader")
const FinalDeshilado = preload("final_deshilado.gd")
## Escena del primer nivel (el_hilo_que_no_teji_stealth.tscn).
const SIGUIENTE_ESCENA: String = "uid://byj0ojaw486bm"

const MANCHITAS_ZOOM: float = 3.6
const LINO_ZOOM_INICIAL: float = 2.05
const LINO_ZOOM_FINAL: float = 3.6
const LINO_ZOOM_DURATION: float = 36.7

const LINO_POV_TIME: float = 8.0
const VUELTA_A_MANCHITAS_TIME: float = 12.3
const VUELTA_A_LINO_TIME: float = 17.1
const LINO_SE_DUERME_TIME: float = 23.66
const PUERTA_ABIERTA_TIME: float = 29.619
const DIALOGO_START_TIME: float = 36.45
const DIALOGO_PUERTA_TIME: float = 42.75
const DIALOGO_CHARCO_TIME: float = 51.45
const ULTIMO_RAYO_TIME: float = 64.67

const NIEBLA_INICIAL: float = 0.3
const NIEBLA_RADIO_MINIMO: float = 0.42
const NIEBLA_RADIO_AL_LLORAR: float = 0.17
const NIEBLA_AL_ABRIR_LA_PUERTA: float = 0.45
const DURACION_HACERSE_NOTAR: float = 2.5
const MARGEN_ANTES_DEL_RAYO: float = 1.5
const FRENTE_DE_LA_NIEBLA: float = 1.3
const DURACION_NIEBLA_INICIAL: float = 4.0
const CAPA_DE_LA_NIEBLA: int = 1

const SOMBRA_EMPIEZA_TIME: float = 1.0
const SOMBRA_FIN_CUADRO_2_TIME: float = 7.33
const SOMBRA_FUERA_DE_CUADRO: float = 0.86
const SOMBRA_AL_FIN_DEL_CUADRO_2: float = 0.25
const SOMBRA_AL_EMPEZAR_EL_CUADRO_4: float = 0.2
const SOMBRA_AL_FIN_DEL_CUADRO_4: float = -0.2

var siguiendo_a_lino: bool = false
var zoom_lino_activo: bool = false
var zoom_lino_transcurrido: float = 0.0
var niebla_bordes: ShaderMaterial
var capa_sombra: CanvasLayer
var material_sombra: ShaderMaterial
var viendo_a_manchitas: bool = false
var niebla_sigue_a_lino: bool = false

@onready var camara: Camera2D = $"../Camera2D"
@onready var destello: ColorRect = $"../FlashOverlay/ColorRect"
@onready var animacion_de_lino: AnimationPlayer = $"../OnTheGround/AnimationPlayer"
@onready var manchitas: Node2D = $"../OnTheGround/Manchitas"
@onready var lino: Node2D = $"../OnTheGround/LinoMover/Lino"
@onready var cinematic: Cinematic = $"../Cinematic"


func _ready() -> void:
	ElHiloQueNoTejiIdiomas.registrar()
	ElHiloQueNoTejiState.resetear_saturacion()

	add_child(BloqueoSaltoDialogo.new())

	intro_finished.connect(_on_intro_finished)

	if cinematic:
		cinematic.autostart = false

	_empezar_intro()


func _process(delta: float) -> void:
	_actualizar_cuadro_de_manchitas()
	if niebla_sigue_a_lino and niebla_bordes and lino:
		var pantalla := get_viewport().get_visible_rect().size
		niebla_bordes.set_shader_parameter(
			"centro", lino.get_global_transform_with_canvas().origin / pantalla
		)
	if viendo_a_manchitas:
		return
	if siguiendo_a_lino and camara and lino:
		camara.global_position = lino.global_position
		if zoom_lino_activo:
			zoom_lino_transcurrido += delta
			var progreso: float = clampf(zoom_lino_transcurrido / LINO_ZOOM_DURATION, 0.0, 1.0)
			var zoom_actual: float = lerpf(LINO_ZOOM_INICIAL, LINO_ZOOM_FINAL, progreso)
			camara.zoom = Vector2(zoom_actual, zoom_actual)
			if progreso >= 1.0:
				zoom_lino_activo = false


func _empezar_intro() -> void:
	if camara and manchitas:
		_encuadrar_a_manchitas()
		camara.make_current()
	else:
		push_error("No se encontró la Camera2D o Manchitas.")

	siguiendo_a_lino = false
	zoom_lino_activo = false
	zoom_lino_transcurrido = 0.0

	destello.modulate.a = 0.0

	if animacion_de_lino:
		animacion_de_lino.stop()

	await get_tree().process_frame
	await _correr_secuencia()


func _encuadrar_a_manchitas() -> void:
	camara.global_position = manchitas.global_position
	camara.zoom = Vector2(MANCHITAS_ZOOM, MANCHITAS_ZOOM)


func _correr_secuencia() -> void:
	if animacion_de_lino:
		animacion_de_lino.play("intro_cinematic")

		_preparar_sombra_sobre_manchitas()
		await get_tree().create_timer(LINO_POV_TIME).timeout
		_empezar_pesadilla_al_dormir()

		if camara and lino:
			camara.zoom = Vector2(LINO_ZOOM_INICIAL, LINO_ZOOM_INICIAL)

			siguiendo_a_lino = true
			zoom_lino_transcurrido = 0.0
			zoom_lino_activo = true
			camara.global_position = lino.global_position
		else:
			push_error("No se encontró la Camera2D o Lino.")

		await _esperar_hasta_posicion(PUERTA_ABIERTA_TIME)
		_sonar_puerta()
		_cerrar_la_niebla_sobre_lino()

		await _esperar_hasta_posicion(DIALOGO_START_TIME)
		_mostrar_dialogo("start")
		await _esperar_hasta_posicion(DIALOGO_PUERTA_TIME)
		_mostrar_dialogo("puerta")
		await _esperar_hasta_posicion(DIALOGO_CHARCO_TIME)
		_mostrar_dialogo("charco")

		await _esperar_hasta_posicion(ULTIMO_RAYO_TIME)
		siguiendo_a_lino = false
		zoom_lino_activo = false
		var final := FinalDeshilado.new()
		add_child(final)
		await final.reproducir(lino as AnimatedSprite2D, niebla_bordes)

	else:
		push_error("No se encontró el AnimationPlayer en la ruta especificada.")

	intro_finished.emit()


func _crear_capa_de_niebla(visible_al_crear: bool) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SHADER_NIEBLA
	material.set_shader_parameter("lateral", false)
	material.set_shader_parameter("frente", FRENTE_DE_LA_NIEBLA)
	material.set_shader_parameter("intensidad", 0.0)
	material.set_shader_parameter("radio_minimo", NIEBLA_RADIO_MINIMO)
	material.set_shader_parameter("centro", Vector2(0.5, 0.5))
	material.set_shader_parameter("cubrir", 0.0)
	var capa := CanvasLayer.new()
	capa.layer = CAPA_DE_LA_NIEBLA
	capa.visible = visible_al_crear
	var velo := ColorRect.new()
	velo.material = material
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.add_child(velo)
	get_parent().add_child(capa)
	return material


func _empezar_pesadilla_al_dormir() -> void:
	await _esperar_hasta_posicion(LINO_SE_DUERME_TIME)
	niebla_bordes = _crear_capa_de_niebla(true)
	_oscurecer_pesadilla(NIEBLA_INICIAL, DURACION_NIEBLA_INICIAL)


func _cerrar_la_niebla_sobre_lino() -> void:
	if not niebla_bordes:
		return
	niebla_sigue_a_lino = true
	var duracion := ULTIMO_RAYO_TIME - PUERTA_ABIERTA_TIME - MARGEN_ANTES_DEL_RAYO
	var espesar := create_tween()
	espesar.tween_property(
		niebla_bordes,
		"shader_parameter/intensidad",
		NIEBLA_AL_ABRIR_LA_PUERTA,
		DURACION_HACERSE_NOTAR
	)
	espesar.tween_property(
		niebla_bordes, "shader_parameter/intensidad", 1.0, duracion - DURACION_HACERSE_NOTAR
	)
	var cerrar := create_tween()
	cerrar.tween_property(
		niebla_bordes, "shader_parameter/radio_minimo", NIEBLA_RADIO_AL_LLORAR, duracion
	)


func _oscurecer_pesadilla(intensidad: float, duracion: float) -> void:
	if not niebla_bordes:
		return
	var cambio := create_tween()
	cambio.tween_property(niebla_bordes, "shader_parameter/intensidad", intensidad, duracion)


func _preparar_sombra_sobre_manchitas() -> void:
	material_sombra = _crear_capa_de_niebla(false)
	material_sombra.set_shader_parameter("lateral", true)
	# la capa que acaba de añadir _crear_capa_de_niebla es el último hijo
	capa_sombra = get_parent().get_child(-1) as CanvasLayer


func _actualizar_cuadro_de_manchitas() -> void:
	if not animacion_de_lino or not animacion_de_lino.is_playing():
		return
	var t := animacion_de_lino.current_animation_position
	var ultima_vez := t >= VUELTA_A_MANCHITAS_TIME and t < VUELTA_A_LINO_TIME
	viendo_a_manchitas = t < LINO_POV_TIME or ultima_vez
	if ultima_vez and camara and manchitas:
		_encuadrar_a_manchitas()

	if not capa_sombra or not manchitas:
		return
	capa_sombra.visible = viendo_a_manchitas and t >= SOMBRA_EMPIEZA_TIME
	if not capa_sombra.visible:
		return
	var avance := SOMBRA_FUERA_DE_CUADRO
	if ultima_vez:
		avance = lerpf(
			SOMBRA_AL_EMPEZAR_EL_CUADRO_4,
			SOMBRA_AL_FIN_DEL_CUADRO_4,
			inverse_lerp(VUELTA_A_MANCHITAS_TIME, VUELTA_A_LINO_TIME, t)
		)
	else:
		avance = lerpf(
			SOMBRA_FUERA_DE_CUADRO,
			SOMBRA_AL_FIN_DEL_CUADRO_2,
			clampf(inverse_lerp(SOMBRA_EMPIEZA_TIME, SOMBRA_FIN_CUADRO_2_TIME, t), 0.0, 1.0)
		)
	var ancho := get_viewport().get_visible_rect().size.x
	var manchitas_en_pantalla := manchitas.get_global_transform_with_canvas().origin.x / ancho
	material_sombra.set_shader_parameter("frente", manchitas_en_pantalla + avance)


func _sonar_puerta() -> void:
	var puerta := AudioStreamPlayer.new()
	puerta.stream = PUERTA_ABRIENDOSE
	puerta.bus = &"SFX"
	add_child(puerta)
	puerta.play()
	puerta.finished.connect(puerta.queue_free)


func _esperar_hasta_posicion(tiempo_objetivo: float) -> void:
	while animacion_de_lino.current_animation_position < tiempo_objetivo:
		await get_tree().process_frame


func _mostrar_dialogo(cue: String) -> void:
	if cinematic == null:
		push_error("No se encontró el nodo Cinematic.")
		return
	cinematic.dialogue_title = cue

	# Cinematic se salta el diálogo si la marca ya es true, y la deja así al terminar
	GameState.scene.intro_dialogue_shown = false
	cinematic.start()


func _on_intro_finished() -> void:
	# en false para que el primer nivel sí muestre su diálogo inicial
	GameState.scene.intro_dialogue_shown = false

	if ResourceLoader.exists(SIGUIENTE_ESCENA):
		SceneSwitcher.change_to_file_with_transition(SIGUIENTE_ESCENA)
	else:
		push_error("No se encontró el archivo de escena en: ", SIGUIENTE_ESCENA)
