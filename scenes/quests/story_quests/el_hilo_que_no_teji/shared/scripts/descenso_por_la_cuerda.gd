# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name DescensoPorLaCuerda
extends CanvasLayer
## La cuerda por la que Lino baja al nivel, dibujada en primer plano.

## Se emite cuando Lino termina de bajar y ya puede moverse.
signal bajada_terminada

const AyudasDeEscena = preload("ayudas_de_escena.gd")

const SHADER_CUERDA: Shader = preload("../shaders/cuerda_en_primer_plano.gdshader")
const ZOOM_AL_EMPEZAR: float = 0.42
const OSCURIDAD_AL_EMPEZAR: float = 0.8
const PAUSA_ARRIBA: float = 0.6
const DURACION_DESCENSO: float = 5.0
const ALTURA_DE_LA_CAIDA: float = 34.0
const DURACION_APARECER: float = 0.28
const DURACION_APARECER_COLOR: float = DURACION_APARECER * 0.5
const DURACION_SOLTAR_CAMARA: float = 0.8
const HEBRAS_AL_BAJAR: float = 14.0
const SPRITE_DEL_JUGADOR: String = "%PlayerSprite"

# Es static porque cuando Lino muere y la escena se recarga, esta cuerda se vuelve a
# crear y perdería el valor. Guarda el número de partida en que ya se hizo la bajada,
# para que la cinemática salga una sola vez por partida y no en cada reintento
static var partida_vista: int = -1

var jugador: Player
var material_cuerda: ShaderMaterial
var pie_de_la_cuerda: Vector2
var camara_suelta: float = 1.0


static func toca_verlo() -> bool:
	if partida_vista == ElHiloQueNoTejiState.numero_partida:
		return false
	partida_vista = ElHiloQueNoTejiState.numero_partida
	return true


func _ready() -> void:
	layer = 0
	jugador = get_tree().get_first_node_in_group("player") as Player
	if not jugador:
		queue_free()
		return
	pie_de_la_cuerda = jugador.global_position
	_crear_cuerda()
	if toca_verlo():
		_bajar.call_deferred()


func _crear_cuerda() -> void:
	material_cuerda = ShaderMaterial.new()
	material_cuerda.shader = SHADER_CUERDA
	material_cuerda.set_shader_parameter("corrimiento", 0.0)
	material_cuerda.set_shader_parameter("desvanecer", 0.0)
	var cuerda := AyudasDeEscena.rect_de_pantalla_completa()
	cuerda.material = material_cuerda
	add_child(cuerda)


func _process(_delta: float) -> void:
	var vista := get_viewport()
	var tamano_pantalla := vista.get_visible_rect().size
	material_cuerda.set_shader_parameter("pantalla", tamano_pantalla)
	var ancla := vista.get_canvas_transform() * pie_de_la_cuerda
	material_cuerda.set_shader_parameter("ancla", ancla)
	material_cuerda.set_shader_parameter(
		"bajo_la_camara", ancla.lerp(tamano_pantalla / 2.0, camara_suelta)
	)
	var camara_actual := vista.get_camera_2d()
	if camara_actual:
		material_cuerda.set_shader_parameter("zoom", camara_actual.zoom.x)


func _bajar() -> void:
	camara_suelta = 0.0
	# Durante la bajada no se ve el HUD: reaparece cuando Lino ya puede moverse.
	ReglaHilosHud.ocultar_en_animacion(true)
	jugador.take_control(self)
	jugador.velocity = Vector2.ZERO
	var color_original := jugador.modulate
	jugador.modulate.a = 0.0

	var oscuridad := _crear_oscuridad()

	var camara := get_viewport().get_camera_2d()
	var zoom_normal := Vector2.ONE
	var suavizado := false
	if camara:
		zoom_normal = camara.zoom
		suavizado = camara.position_smoothing_enabled
		camara.position_smoothing_enabled = false
		camara.zoom = zoom_normal * ZOOM_AL_EMPEZAR
	await get_tree().create_timer(PAUSA_ARRIBA).timeout

	await _animar_descenso(oscuridad, camara, zoom_normal)
	await _aparecer_jugador(color_original)

	if camara:
		camara.position_smoothing_enabled = suavizado
	jugador.return_control(self)
	ReglaHilosHud.ocultar_en_animacion(false)
	oscuridad.queue_free()
	create_tween().tween_property(self, "camara_suelta", 1.0, DURACION_SOLTAR_CAMARA)
	bajada_terminada.emit()


func _animar_descenso(oscuridad: ColorRect, camara: Camera2D, zoom_normal: Vector2) -> void:
	var bajar := create_tween().set_parallel(true)
	bajar.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bajar.tween_property(
		material_cuerda, "shader_parameter/corrimiento", HEBRAS_AL_BAJAR, DURACION_DESCENSO
	)
	bajar.tween_property(oscuridad, "color:a", 0.0, DURACION_DESCENSO)
	if camara:
		bajar.tween_property(camara, "zoom", zoom_normal, DURACION_DESCENSO)
	await bajar.finished


func _crear_oscuridad() -> ColorRect:
	var oscuridad := AyudasDeEscena.rect_de_pantalla_completa()
	oscuridad.color = Color(0, 0, 0, OSCURIDAD_AL_EMPEZAR)
	add_child(oscuridad)
	move_child(oscuridad, 0)
	return oscuridad


func _aparecer_jugador(color_original: Color) -> void:
	var figura := jugador.get_node_or_null(SPRITE_DEL_JUGADOR) as AnimatedSprite2D
	var aparecer := create_tween().set_parallel(true)
	aparecer.tween_property(jugador, "modulate", color_original, DURACION_APARECER_COLOR)
	if figura:
		var lugar := figura.position
		figura.position = lugar - Vector2(0, ALTURA_DE_LA_CAIDA)
		(
			aparecer
			. tween_property(figura, "position", lugar, DURACION_APARECER)
			. set_trans(Tween.TRANS_BOUNCE)
			. set_ease(Tween.EASE_OUT)
		)
	await aparecer.finished
