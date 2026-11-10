# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node
## El final de la intro: Lino se deshila.

## Sprites de Elián (el_hilo_que_no_teji_boss_intro.tres).
const FIGURA_ELIAN: SpriteFrames = preload("uid://bwf57ox164emj")
## elian_laugh.wav
const RISA_ELIAN: AudioStream = preload("uid://b6ar0l4qv6p7k")
const SHADER_NIEBLA: Shader = preload("../../shared/shaders/niebla_del_deshilado.gdshader")
const SHADER_SATURACION: Shader = preload("../../shared/shaders/saturacion_de_lino.gdshader")
const SHADER_SILUETA: Shader = preload("../../shared/shaders/silueta_de_elian.gdshader")
const SHADER_HAZ: Shader = preload("../../shared/shaders/haz_de_luz.gdshader")
const LUZ_SIN_HAZ := Color(0.5, 0.5, 0.56, 1.0)
const LUZ_BAJO_EL_HAZ := Color(1.0, 0.99, 0.95, 1.0)
const DURACION_ENCENDER_HAZ: float = 0.5
const LUZ_DE_LA_NIEBLA: Array[float] = [0.62, 0.34, 0.13]
const COLOR_DE_LA_NIEBLA := Color(0.72, 0.74, 0.8, 1.0)
const COLOR_DE_LA_SOMBRA := Color(0.2, 0.21, 0.27, 1.0)

const COLORES_DE_LOS_HILOS: Array[Color] = [
	Color(0.55, 1.0, 0.6), Color(1.0, 0.9, 0.45), Color(1.0, 0.5, 0.45)
]
const ELIAN_SOBRE_LOS_PIES := Vector2(-14.0, -81.0)
const PIES_DE_LINO: float = 32.0
const MANO_DE_ELIAN := Vector2(96.0, 22.0)
const TAMANO_DE_LA_MANO: float = 0.8
const CUADRO_DE_LA_MANO: int = 2
const BALANCEO_DE_LA_MANO: Array[float] = [0.0, -2.0, -4.0, -2.0]
const ESQUINA_DE_LA_CABEZA := Vector2(-57.0, -70.0)
const LUZ_SOBRE_LINO := Color(0.8, 0.8, 0.86, 1.0)
const MANO_VISIBLE: float = 0.62
const DETALLE_DE_ELIAN: float = 0.3
const OPACIDAD_DEL_VELO: float = 0.38
const VOLUMEN_RISA: float = 0.9

const DURACION_DESTELLO: float = 1.2
const DURACION_APAGAR_AMBIENTE: float = 2.5
const DURACION_CUBRIR: float = 1.6
const PAUSA_EN_EL_GRIS: float = 0.7
const DURACION_OJOS: float = 0.9
const DURACION_SILUETA: float = 2.4
const PAUSA_ANTES_DE_DESHILAR: float = 0.5
const PAUSA_ENTRE_HILOS: float = 0.35
const DURACION_PERDERSE: float = 1.0
const DURACION_OJOS_AL_FINAL: float = 0.4
const PAUSA_APAGADO_DEL_PARPADEO: float = 0.12
const FRACCION_LINO_SE_DESVANECE: float = 0.7
const EXTRA_SILENCIAR_RISA: float = 0.6

const CAPA_DEL_FINAL: int = 2
const VOLUMEN_SILENCIO_DB: float = -60.0
const NOMBRES_DE_LLUVIA: Array[String] = ["Rain", "Rain2", "Rain3"]
const PARAMETROS_DE_SILUETA: Array[String] = ["sombra", "ojos", "detalle", "mano"]
const NIVELES_DE_ENCENDIDO: Array[float] = [0.7, 0.15, 1.0]

const CUERPO_DE_LINO := Rect2(Vector2(-13.0, -20.0), Vector2(26.0, 44.0))

const FRACCION_ANTES_DEL_PARPADEO: float = 0.45
const FRACCION_HASTA_EL_PARPADEO: float = 0.2
const FRACCION_DESPUES_DEL_PARPADEO: float = 0.2
const DETALLE_AL_PERDER_COLOR: float = 0.55
const DURACION_DETALLE_SUBE: float = 0.2
const DURACION_DETALLE_BAJA: float = 0.5

var pantalla: Vector2
var capa: CanvasLayer
var elian: AnimatedSprite2D
var cabeza: AnimatedSprite2D
var lugar_de_elian: Vector2
var escala_de_elian: float
var materiales_de_elian: Array[ShaderMaterial] = []
var materiales_de_niebla: Array[ShaderMaterial] = []
var material_haz: ShaderMaterial
var hebras: HebrasDeHilo
var lino_copia: AnimatedSprite2D
var material_lino: ShaderMaterial
var luz_de_la_niebla: float = 1.0


func reproducir(lino: AnimatedSprite2D, niebla: ShaderMaterial) -> void:
	pantalla = get_viewport().get_visible_rect().size
	var mundo := get_parent().get_parent()
	_pausar_el_mundo(mundo)
	_apagar_el_ambiente(mundo)
	_crear_copia_de_lino(lino)

	var escala := lino_copia.scale.x
	var pies := lino_copia.position + Vector2(0, PIES_DE_LINO * escala)
	await _cubrir_de_niebla(mundo, niebla)
	if niebla:
		materiales_de_niebla.append(niebla)
	await get_tree().create_timer(PAUSA_EN_EL_GRIS).timeout
	await _encender_haz(pies)

	_crear_a_elian(pies, escala)
	await _cambiar_a_elian("ojos", 1.0, DURACION_OJOS).finished

	cabeza.play(&"laugh")
	var risa := _reproducir_risa()
	_cambiar_a_elian("detalle", DETALLE_DE_ELIAN, DURACION_SILUETA)
	await _cambiar_a_elian("mano", MANO_VISIBLE, DURACION_SILUETA).finished
	await get_tree().create_timer(PAUSA_ANTES_DE_DESHILAR).timeout

	await _soltar_las_hebras_de_lino()
	if lino_copia.sprite_frames.has_animation(&"defeated"):
		lino_copia.play(&"defeated")
		await lino_copia.animation_finished
	await _perder_en_la_niebla(risa)


func _pausar_el_mundo(mundo: Node) -> void:
	var animacion := mundo.get_node_or_null("OnTheGround/AnimationPlayer") as AnimationPlayer
	if animacion:
		animacion.pause()
	for sprite in mundo.get_node("OnTheGround").find_children("*", "AnimatedSprite2D", true, false):
		sprite.pause()


func _apagar_el_ambiente(mundo: Node) -> void:
	var apagar := create_tween().set_parallel(true)
	apagar.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	for nombre in NOMBRES_DE_LLUVIA:
		var lluvia := mundo.get_node_or_null(nombre) as GPUParticles2D
		if lluvia:
			apagar.tween_property(lluvia, "modulate:a", 0.0, DURACION_APAGAR_AMBIENTE)
	var ambiente := mundo.get_node_or_null("AudioStreamPlayer2D") as AudioStreamPlayer2D
	if ambiente:
		apagar.tween_property(ambiente, "volume_db", VOLUMEN_SILENCIO_DB, DURACION_APAGAR_AMBIENTE)


func _crear_copia_de_lino(lino: AnimatedSprite2D) -> void:
	capa = CanvasLayer.new()
	capa.layer = CAPA_DEL_FINAL
	add_child(capa)
	material_lino = ShaderMaterial.new()
	material_lino.shader = SHADER_SATURACION
	material_lino.set_shader_parameter("saturation", 1.0)
	lino_copia = AnimatedSprite2D.new()
	lino_copia.sprite_frames = lino.sprite_frames
	lino_copia.animation = lino.animation
	lino_copia.frame = lino.frame
	lino_copia.flip_h = lino.flip_h
	lino_copia.centered = lino.centered
	lino_copia.offset = lino.offset
	lino_copia.material = material_lino
	lino_copia.modulate = LUZ_SOBRE_LINO
	# la capa no tiene cámara: posición y escala se copian ya en pantalla
	var en_pantalla := lino.get_global_transform_with_canvas()
	lino_copia.position = en_pantalla.origin
	lino_copia.scale = en_pantalla.get_scale()
	capa.add_child(lino_copia)
	lino.visible = false


func _cubrir_de_niebla(mundo: Node, niebla: ShaderMaterial) -> void:
	var cubrir := create_tween().set_parallel(true)
	cubrir.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if niebla:
		cubrir.tween_property(niebla, "shader_parameter/intensidad", 1.0, DURACION_CUBRIR)
		cubrir.tween_property(niebla, "shader_parameter/cubrir", 1.0, DURACION_CUBRIR)
	var destello := mundo.get_node_or_null("FlashOverlay/LightningFlash") as ColorRect
	if destello:
		cubrir.tween_property(destello, "color", Color(1, 1, 1, 0), DURACION_DESTELLO)
	cubrir.tween_property(lino_copia, "modulate", LUZ_SIN_HAZ, DURACION_CUBRIR)
	await cubrir.finished


func _crear_a_elian(pies: Vector2, escala: float) -> void:
	escala_de_elian = escala * TAMANO_DE_LA_MANO
	lugar_de_elian = (
		pies + ELIAN_SOBRE_LOS_PIES * escala + MANO_DE_ELIAN * (escala - escala_de_elian)
	)
	elian = AnimatedSprite2D.new()
	elian.sprite_frames = FIGURA_ELIAN
	elian.animation = &"idle"
	elian.position = lugar_de_elian
	elian.scale = Vector2(escala_de_elian, escala_de_elian)
	elian.frame = CUADRO_DE_LA_MANO

	cabeza = AnimatedSprite2D.new()
	cabeza.sprite_frames = FIGURA_ELIAN
	cabeza.animation = &"laugh"
	var medida := cabeza.sprite_frames.get_frame_texture(&"laugh", 0).get_size()
	cabeza.position = pies + (ELIAN_SOBRE_LOS_PIES + ESQUINA_DE_LA_CABEZA + medida / 2.0) * escala
	cabeza.scale = Vector2(escala, escala)

	var material_cuerpo := _crear_material_de_silueta()
	var material_cabeza := _crear_material_de_silueta()
	elian.material = material_cuerpo
	cabeza.material = material_cabeza
	materiales_de_elian = [material_cuerpo, material_cabeza]
	cabeza.frame_changed.connect(_balancear_la_mano)

	# orden final de abajo a arriba: Elián, su cabeza, el velo y Lino
	capa.add_child(cabeza)
	capa.move_child(cabeza, 0)
	capa.add_child(elian)
	capa.move_child(elian, 0)
	var velo := _crear_velo()
	capa.add_child(velo)
	capa.move_child(velo, 2)
	materiales_de_niebla.append(velo.material as ShaderMaterial)
	hebras = HebrasDeHilo.new()
	capa.add_child(hebras)


func _crear_material_de_silueta() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SHADER_SILUETA
	for parametro in PARAMETROS_DE_SILUETA:
		material.set_shader_parameter(parametro, 0.0)
	return material


func _balancear_la_mano() -> void:
	var sube := BALANCEO_DE_LA_MANO[cabeza.frame % BALANCEO_DE_LA_MANO.size()]
	if not cabeza.is_playing():
		sube = 0.0
	elian.position = lugar_de_elian + Vector2(0, sube * escala_de_elian)
	if hebras:
		hebras.movimiento_del_destino = Vector2(0, sube * escala_de_elian)


func _reproducir_risa() -> AudioStreamPlayer:
	var risa := AudioStreamPlayer.new()
	risa.stream = RISA_ELIAN
	risa.bus = &"SFX"
	risa.volume_db = linear_to_db(VOLUMEN_RISA)
	add_child(risa)
	risa.play()
	return risa


func _soltar_las_hebras_de_lino() -> void:
	var cuerpo := Rect2(
		lino_copia.position + CUERPO_DE_LINO.position * lino_copia.scale.x,
		CUERPO_DE_LINO.size * lino_copia.scale.x
	)
	var mano := lugar_de_elian + MANO_DE_ELIAN * escala_de_elian
	var tandas := COLORES_DE_LOS_HILOS.size()
	for i in tandas:
		var duracion := hebras.soltar(cuerpo, mano, COLORES_DE_LOS_HILOS[i])
		var saturacion := 1.0 - float(i + 1) / tandas
		_oscurecer_la_niebla(LUZ_DE_LA_NIEBLA[i], duracion + PAUSA_ENTRE_HILOS)
		_programar_perdida_de_color(duracion, saturacion)
		await get_tree().create_timer(duracion + PAUSA_ENTRE_HILOS).timeout


func _programar_perdida_de_color(duracion_de_la_tanda: float, saturacion: float) -> void:
	var perder := create_tween()
	perder.tween_interval(duracion_de_la_tanda * FRACCION_ANTES_DEL_PARPADEO)
	perder.tween_interval(duracion_de_la_tanda * FRACCION_HASTA_EL_PARPADEO)
	perder.tween_callback(_parpadear.bind(saturacion))
	perder.tween_interval(duracion_de_la_tanda * FRACCION_DESPUES_DEL_PARPADEO)
	perder.tween_callback(
		_cambiar_a_elian.bind("detalle", DETALLE_AL_PERDER_COLOR, DURACION_DETALLE_SUBE)
	)
	perder.tween_interval(DURACION_DETALLE_SUBE)
	perder.tween_callback(_cambiar_a_elian.bind("detalle", DETALLE_DE_ELIAN, DURACION_DETALLE_BAJA))


func _perder_en_la_niebla(risa: AudioStreamPlayer) -> void:
	var perderse := create_tween().set_parallel(true)
	perderse.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	perderse.tween_property(
		lino_copia, "modulate:a", 0.0, DURACION_PERDERSE * FRACCION_LINO_SE_DESVANECE
	)
	perderse.tween_property(material_haz, "shader_parameter/brillo", 0.0, DURACION_PERDERSE)
	_cambiar_a_elian("sombra", 0.0, DURACION_PERDERSE)
	_cambiar_a_elian("mano", 0.0, DURACION_PERDERSE)
	perderse.tween_property(
		risa, "volume_db", VOLUMEN_SILENCIO_DB, DURACION_PERDERSE + EXTRA_SILENCIAR_RISA
	)
	await perderse.finished
	await _cambiar_a_elian("ojos", 0.0, DURACION_OJOS_AL_FINAL).finished


func _encender_haz(pies: Vector2) -> void:
	material_haz = ShaderMaterial.new()
	material_haz.shader = SHADER_HAZ
	material_haz.set_shader_parameter("brillo", 0.0)
	material_haz.set_shader_parameter("pie", pies / pantalla)
	var haz := ColorRect.new()
	haz.material = material_haz
	haz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	haz.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.add_child(haz)
	capa.move_child(haz, lino_copia.get_index())
	var encender := create_tween()
	for nivel in NIVELES_DE_ENCENDIDO:
		_brillo_del_haz(encender, nivel, DURACION_ENCENDER_HAZ / NIVELES_DE_ENCENDIDO.size())
	await encender.finished


func _parpadear(saturacion: float) -> void:
	var parpadeo := create_tween()
	_brillo_del_haz(parpadeo, 0.1, 0.05)
	_brillo_del_haz(parpadeo, 1.0, 0.05)
	_brillo_del_haz(parpadeo, 0.05, 0.08)
	parpadeo.tween_callback(func(): material_lino.set_shader_parameter("saturation", saturacion))
	parpadeo.tween_interval(PAUSA_APAGADO_DEL_PARPADEO)
	_brillo_del_haz(parpadeo, 1.0, 0.06)


func _brillo_del_haz(animacion: Tween, nivel: float, duracion: float) -> void:
	animacion.tween_property(material_haz, "shader_parameter/brillo", nivel, duracion)
	animacion.parallel().tween_property(
		lino_copia, "modulate", LUZ_SIN_HAZ.lerp(LUZ_BAJO_EL_HAZ, nivel), duracion
	)


func _oscurecer_la_niebla(luz: float, duracion: float) -> void:
	var desde := luz_de_la_niebla
	luz_de_la_niebla = luz
	var oscurecer := create_tween()
	oscurecer.tween_method(_poner_luz_a_la_niebla, desde, luz, duracion)


func _poner_luz_a_la_niebla(luz: float) -> void:
	var niebla := _con_luz(COLOR_DE_LA_NIEBLA, luz)
	for material in materiales_de_niebla:
		material.set_shader_parameter("color_niebla", niebla)
	var sombra := _con_luz(COLOR_DE_LA_SOMBRA, luz)
	for material in materiales_de_elian:
		material.set_shader_parameter("color_sombra", sombra)


func _con_luz(color: Color, luz: float) -> Color:
	return Color(color.r * luz, color.g * luz, color.b * luz, 1.0)


func _cambiar_a_elian(parametro: String, valor: float, duracion: float) -> Tween:
	var cambio := create_tween().set_parallel(true)
	cambio.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for material in materiales_de_elian:
		# los ojos son solo de la cabeza; el cuerpo no los dibuja
		if parametro == "ojos" and material == materiales_de_elian[0]:
			continue
		cambio.tween_property(material, "shader_parameter/" + parametro, valor, duracion)
	return cambio


func _crear_velo() -> ColorRect:
	var material := ShaderMaterial.new()
	material.shader = SHADER_NIEBLA
	material.set_shader_parameter("lateral", false)
	# Sin "cubrir" (queda en 0): con él la niebla se volvería opaca.
	material.set_shader_parameter("intensidad", 1.0)
	material.set_shader_parameter("radio_minimo", -1.0)
	material.set_shader_parameter("cubrir", 0.0)
	material.set_shader_parameter("opacidad_maxima", OPACIDAD_DEL_VELO)
	var velo := ColorRect.new()
	velo.material = material
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	return velo


class HebrasDeHilo:
	extends Node2D

	const HEBRAS_POR_TANDA: int = 5
	const PIXEL: float = 4.0
	const COLOR_CONTORNO := Color(0.12, 0.12, 0.16, 1.0)
	const RETRASO_ENTRE_HEBRAS: float = 0.14
	const DURACION_SALIR: float = 1.2
	const DURACION_TENDIDA: float = 0.25
	const DURACION_SOLTARSE: float = 1.0
	const ONDA: float = 16.0
	const FRECUENCIA_DE_ONDA: float = 9.0
	const VELOCIDAD_DE_ONDA: float = 2.5
	const DESVIO_EN_LA_MANO := Vector2(24.0, 14.0)
	const CONTROL_DESDE: float = 0.3
	const CONTROL_HASTA: float = 0.6
	const CONTROL_LADO: float = 50.0
	const CONTROL_ARRIBA_MIN: float = 150.0
	const CONTROL_ARRIBA_MAX: float = 260.0

	var hebras: Array[Dictionary] = []
	var tiempo: float = 0.0
	var movimiento_del_destino := Vector2.ZERO

	func soltar(cuerpo: Rect2, destino: Vector2, color: Color) -> float:
		for i in HEBRAS_POR_TANDA:
			var origen := cuerpo.position + Vector2(randf(), randf()) * cuerpo.size
			var control := origen.lerp(destino, randf_range(CONTROL_DESDE, CONTROL_HASTA))
			control += Vector2(
				randf_range(-CONTROL_LADO, CONTROL_LADO),
				randf_range(-CONTROL_ARRIBA_MAX, -CONTROL_ARRIBA_MIN)
			)
			var desvio := Vector2(
				randf_range(-DESVIO_EN_LA_MANO.x, DESVIO_EN_LA_MANO.x),
				randf_range(-DESVIO_EN_LA_MANO.y, DESVIO_EN_LA_MANO.y)
			)
			var hebra := {
				"origen": origen,
				"destino": destino + desvio,
				"control": control,
				"color": color,
				"fase": randf() * TAU,
				"inicio": tiempo + i * RETRASO_ENTRE_HEBRAS,
			}
			hebras.append(hebra)
		return (
			(HEBRAS_POR_TANDA - 1) * RETRASO_ENTRE_HEBRAS
			+ DURACION_SALIR
			+ DURACION_TENDIDA
			+ DURACION_SOLTARSE
		)

	func _process(delta: float) -> void:
		tiempo += delta
		queue_redraw()

	func _draw() -> void:
		for hebra in hebras:
			var t: float = tiempo - hebra.inicio
			if t <= 0.0:
				continue
			var punta := ease(clampf(t / DURACION_SALIR, 0.0, 1.0), 0.5)
			var cola := ease(
				clampf((t - DURACION_SALIR - DURACION_TENDIDA) / DURACION_SOLTARSE, 0.0, 1.0), 2.0
			)
			if cola >= 1.0:
				continue
			var puntos := _puntos(hebra, cola, punta)
			for punto in puntos:
				draw_rect(
					Rect2(punto - Vector2(PIXEL, PIXEL), Vector2(PIXEL, PIXEL) * 3.0),
					COLOR_CONTORNO
				)
			for punto in puntos:
				draw_rect(Rect2(punto, Vector2(PIXEL, PIXEL)), hebra.color)

	func _puntos(hebra: Dictionary, desde: float, hasta: float) -> Array[Vector2]:
		var puntos: Array[Vector2] = []
		var origen: Vector2 = hebra.origen
		var destino: Vector2 = hebra.destino + movimiento_del_destino
		var control: Vector2 = hebra.control
		var lado := (destino - origen).orthogonal().normalized()
		var pasos := int(ceil((hasta - desde) * origen.distance_to(destino) / (PIXEL * 0.5))) + 1
		var anterior := Vector2.INF
		for i in pasos + 1:
			var u := lerpf(desde, hasta, float(i) / pasos)
			var punto := origen.lerp(control, u).lerp(control.lerp(destino, u), u)
			punto += (
				lado
				* sin(u * FRECUENCIA_DE_ONDA + hebra.fase + tiempo * VELOCIDAD_DE_ONDA)
				* ONDA
				* sin(u * PI)
			)
			punto = (punto / PIXEL).floor() * PIXEL
			if punto != anterior:
				puntos.append(punto)
				anterior = punto
		return puntos
