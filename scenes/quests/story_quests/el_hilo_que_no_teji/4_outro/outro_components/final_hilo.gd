# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Control
## El final escrito con hilo, sobre la tela de final_bordado.gd.

enum Tramo { GRUESO, FINO, OCULTO }

const PIXEL: int = 3
const SEGUNDOS_POR_LETRA_CURSIVA: float = 0.32
const SEGUNDOS_POR_LETRA_GRACIAS: float = 0.12
const ESCALA_GRACIAS: float = 0.65
const PAUSA_ENTRE_FRASES: float = 0.6
const DURACION_APARECE_COLLAR: float = 1.0
const DURACION_BRILLO: float = 0.5

const COLOR_CONTORNO := Color(0.12, 0.08, 0.08)
const COLOR_HILO := Color(0.94, 0.9, 0.8)
const COLOR_BRILLO_HILO := Color(1.0, 1.0, 0.97)
const COLOR_CUERO := Color(0.47, 0.27, 0.16)
const COLOR_CUERO_CLARO := Color(0.64, 0.4, 0.24)
const COLOR_CHAPITA := Color(1.0, 0.84, 0.32)
const COLOR_CHAPITA_CLARA := Color(1.0, 0.95, 0.7)
const COLOR_AGUJA := Color(0.62, 0.8, 0.84)

const EM: float = 20.0
const MARGEN_TITULO: float = 60.0
const MARGEN_GRACIAS: float = 64.0
const ESPACIO_DEL_COLLAR: float = 40.0
const SANGRIA_DEL_COLLAR: float = 34.0
const ALTO_SOBRE_EL_RENGLON: float = 2.3
const ALTO_BAJO_EL_RENGLON: float = 1.2
const SEPARACION_GRACIAS_TITULO: float = 1.3
const SEPARACION_FIJA: float = 6.0
const PUNTOS_POR_DETRAS: int = 13
const FRASES_POR_IDIOMA: Dictionary = {
	"en": ["Thank you for weaving...", "the thread I never wove."],
	"fr": ["Merci d'avoir tissé...", "le fil que je n'ai pas tissé."],
}
const MUESTRAS_POR_TRAMO: int = 8
const LARGO_DE_LA_AGUJA: float = 12.0
const SEPARACION_DE_PELUSAS := Vector2(5.0, 11.0)
const SEMILLA_DE_PELUSAS: int = 7
const CURSIVA: Dictionary = preload("final_hilo_letras.gd").CURSIVA
const ESPACIO: float = 0.95

var _lienzo: SubViewport
var _pincel: Node2D
var _vista: TextureRect
var _pantalla: Vector2
var _hilo := PackedVector2Array()
var _largos := PackedFloat32Array()
var _largo_visible: float = 0.0
var _sueltos: Array = []
var _pelusas: Array = []
var _collar_centro := Vector2.ZERO
var _collar_visible: float = 0.0
var _chapita := Vector2.ZERO
var _anudado: bool = false
var _con_aguja: bool = true
var _em: float = EM
var _tramos: Array = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pantalla = get_viewport_rect().size
	_lienzo = SubViewport.new()
	# lienzo chico y estirado con NEAREST: así cada pixel del hilo mide PIXEL pixeles de pantalla
	_lienzo.size = Vector2i((_pantalla / PIXEL).ceil())
	_lienzo.transparent_bg = true
	_lienzo.canvas_item_default_texture_filter = (
		Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	)
	add_child(_lienzo)
	_pincel = Node2D.new()
	_pincel.draw.connect(_dibujar)
	_lienzo.add_child(_pincel)
	_vista = TextureRect.new()
	_vista.texture = _lienzo.get_texture()
	_vista.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_vista.stretch_mode = TextureRect.STRETCH_SCALE
	_vista.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vista.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vista)


# el pincel no se entera de que cambian _largo_visible y _collar_visible (los mueve un tween)
func _process(_delta: float) -> void:
	_pincel.queue_redraw()


func mostrar(lineas: Array[String]) -> void:
	if lineas.is_empty():
		return
	await _mostrar_cursiva(lineas)
	await _anudar()


func _mostrar_cursiva(lineas: Array[String]) -> void:
	var titulo := lineas[-1]
	var gracias := " ".join(lineas.slice(0, lineas.size() - 1))
	var ancho := float(_lienzo.size.x)
	_em = minf(EM, (ancho - MARGEN_TITULO) / _ancho_cursiva(titulo))
	var em_gracias := 0.0
	if not gracias.is_empty():
		em_gracias = minf(_em * ESCALA_GRACIAS, (ancho - MARGEN_GRACIAS) / _ancho_cursiva(gracias))
	var sobre_titulo := (
		_em * ALTO_SOBRE_EL_RENGLON + em_gracias * SEPARACION_GRACIAS_TITULO + SEPARACION_FIJA
	)
	var arriba := sobre_titulo + em_gracias * ALTO_SOBRE_EL_RENGLON
	var abajo := _em * ALTO_BAJO_EL_RENGLON
	var renglon := _lienzo.size.y / 2.0 + (arriba - abajo) / 2.0
	var renglon_gracias := renglon - sobre_titulo
	var titulo_x := (ancho - _ancho_cursiva(titulo) * _em) / 2.0
	var gracias_x := (ancho - _ancho_cursiva(gracias) * em_gracias + ESPACIO_DEL_COLLAR) / 2.0
	if gracias.is_empty():
		gracias_x = titulo_x + SANGRIA_DEL_COLLAR
		renglon_gracias = renglon
	var primer_em := em_gracias if not gracias.is_empty() else _em
	_collar_centro = Vector2(
		gracias_x - SANGRIA_DEL_COLLAR + 10.0, renglon_gracias - primer_em * 0.7
	)
	_chapita = _collar_centro + Vector2(-6.0, 7.0)

	var sueltos_gracias: Array = []
	var sueltos_titulo: Array = []
	var inicio := PackedVector2Array(
		[_chapita, _chapita + Vector2(8.0, 8.0), _chapita + Vector2(18.0, 2.0)]
	)
	var puntos_gracias := _puntos_cursiva(
		gracias, Vector2(gracias_x, renglon_gracias), em_gracias, sueltos_gracias
	)
	var puntos_titulo := _puntos_cursiva(titulo, Vector2(titulo_x, renglon), _em, sueltos_titulo)
	var fin_gracias := 0.0
	var inicio_titulo := 0.0
	if gracias.is_empty():
		_agregar_tramo(_suavizar(inicio + puntos_titulo), Tramo.GRUESO)
	else:
		_agregar_tramo(_suavizar(inicio + puntos_gracias), Tramo.FINO)
		var salida := _pasar_por_detras_de_la_tela(puntos_gracias, sueltos_gracias)
		fin_gracias = _largos[-1]
		var vuelta := PackedVector2Array(
			[
				salida,
				salida + Vector2(4.0, em_gracias * 0.6),
				salida + Vector2(2.0, em_gracias * 1.8),
				Vector2((salida.x + titulo_x) / 2.0, renglon_gracias + em_gracias * 2.2),
				Vector2(titulo_x - 10.0, renglon - _em * 1.1),
				Vector2(titulo_x - 6.0, renglon - _em * 0.1),
			]
		)
		var desde := _hilo.size()
		_hilo.append_array(_suavizar(vuelta + puntos_titulo))
		var corte := desde + vuelta.size() * MUESTRAS_POR_TRAMO
		_tramos.append([desde, corte, Tramo.FINO])
		_tramos.append([corte, _hilo.size() - 1, Tramo.GRUESO])
		inicio_titulo = fin_gracias
	_medir_hilo()
	for trazo: PackedVector2Array in sueltos_gracias:
		_sueltos.append([trazo, _largo_en(trazo[0], 0.0, fin_gracias), Tramo.FINO])
	for trazo: PackedVector2Array in sueltos_titulo:
		_sueltos.append([trazo, _largo_en(trazo[0], inicio_titulo, _largos[-1]), Tramo.GRUESO])

	await _aparecer_collar()
	if not gracias.is_empty():
		var letras_gracias := gracias.replace(" ", "").length()
		await _avanzar_hilo(letras_gracias * SEGUNDOS_POR_LETRA_GRACIAS, fin_gracias)
		await get_tree().create_timer(PAUSA_ENTRE_FRASES).timeout
		_largo_visible = inicio_titulo
	var letras := titulo.replace(" ", "").length()
	await _avanzar_hilo(letras * SEGUNDOS_POR_LETRA_CURSIVA)


func _pasar_por_detras_de_la_tela(
	puntos_gracias: PackedVector2Array, sueltos_gracias: Array
) -> Vector2:
	var salida := puntos_gracias[-1]
	if sueltos_gracias.is_empty():
		return salida
	var ultimo: PackedVector2Array = sueltos_gracias[-1]
	if ultimo.size() == 1 and ultimo[0].x > salida.x:
		salida = ultimo[0]
		var detras := PackedVector2Array()
		for paso in PUNTOS_POR_DETRAS:
			detras.append(puntos_gracias[-1].lerp(salida, paso / float(PUNTOS_POR_DETRAS - 1)))
		_agregar_tramo(detras, Tramo.OCULTO)
	return salida


func _agregar_tramo(puntos: PackedVector2Array, tipo: Tramo) -> void:
	var desde := _hilo.size()
	_hilo.append_array(puntos)
	_tramos.append([desde, _hilo.size() - 1, tipo])
	_medir_hilo()


func _ancho_cursiva(texto: String) -> float:
	var ancho := 0.0
	for letra in texto:
		var cual := _letra_cursiva(letra)
		ancho += CURSIVA[cual][0] if CURSIVA.has(cual) else ESPACIO
	return ancho


func _letra_cursiva(letra: String) -> String:
	return letra if CURSIVA.has(letra) else letra.to_lower()


static func frases_para_el_idioma(espanol: Array[String]) -> Array[String]:
	var idioma := TranslationServer.get_locale().substr(0, 2)
	if not FRASES_POR_IDIOMA.has(idioma):
		return espanol
	var frases: Array[String] = []
	frases.assign(FRASES_POR_IDIOMA[idioma])
	return frases


func _puntos_cursiva(
	texto: String, origen: Vector2, em: float, sueltos: Array
) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	var lapiz := origen.x
	for caracter in texto:
		var letra := _letra_cursiva(caracter)
		if not CURSIVA.has(letra):
			puntos.append(Vector2(lapiz + ESPACIO * em * 0.5, origen.y + em * 0.2))
			lapiz += ESPACIO * em
			continue
		var datos: Array = CURSIVA[letra]
		for punto: Vector2 in datos[1]:
			puntos.append(Vector2(lapiz + punto.x * em, origen.y - punto.y * em))
		for trazo: Array in datos[2]:
			var en_pantalla := PackedVector2Array()
			for punto: Vector2 in trazo:
				en_pantalla.append(Vector2(lapiz + punto.x * em, origen.y - punto.y * em))
			sueltos.append(en_pantalla)
		lapiz += datos[0] * em
	return puntos


func _aparecer_collar() -> void:
	var aparecer := create_tween()
	aparecer.tween_property(self, "_collar_visible", 1.0, DURACION_APARECE_COLLAR)
	await aparecer.finished


func _avanzar_hilo(duracion: float, hasta: float = -1.0) -> void:
	if hasta < 0.0:
		hasta = _largos[-1]
	var avanzar := create_tween()
	avanzar.tween_property(self, "_largo_visible", hasta, duracion)
	await avanzar.finished


func _anudar() -> void:
	_anudado = true
	_con_aguja = false
	var brillar := create_tween()
	brillar.tween_property(_vista, "modulate", Color(1.5, 1.5, 1.4), DURACION_BRILLO * 0.4)
	brillar.tween_property(_vista, "modulate", Color.WHITE, DURACION_BRILLO * 0.6)
	var ladrido := AudioStreamPlayer.new()
	ladrido.stream = Ladrido.SONIDOS.pick_random()
	ladrido.bus = &"SFX"
	add_child(ladrido)
	ladrido.play()
	await brillar.finished


func _suavizar(puntos: PackedVector2Array) -> PackedVector2Array:
	var suave := PackedVector2Array()
	for i in puntos.size() - 1:
		var p0 := puntos[maxi(i - 1, 0)]
		var p1 := puntos[i]
		var p2 := puntos[i + 1]
		var p3 := puntos[mini(i + 2, puntos.size() - 1)]
		for paso in MUESTRAS_POR_TRAMO:
			var t := float(paso) / MUESTRAS_POR_TRAMO
			var t2 := t * t
			var t3 := t2 * t
			suave.append(
				(
					0.5
					* (
						2.0 * p1
						+ (p2 - p0) * t
						+ (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
						+ (3.0 * p1 - p0 - 3.0 * p2 + p3) * t3
					)
				)
			)
	suave.append(puntos[-1])
	return suave


func _medir_hilo() -> void:
	_largos.clear()
	_pelusas.clear()
	var total := 0.0
	for i in _hilo.size():
		if i > 0:
			total += _hilo[i - 1].distance_to(_hilo[i])
		_largos.append(total)
	var azar := RandomNumberGenerator.new()
	# semilla fija: _medir_hilo se repite con cada tramo y las pelusas no deben saltar
	azar.seed = SEMILLA_DE_PELUSAS
	var siguiente := 6.0
	for i in range(1, _hilo.size()):
		if _largos[i] < siguiente:
			continue
		siguiente = _largos[i] + azar.randf_range(SEPARACION_DE_PELUSAS.x, SEPARACION_DE_PELUSAS.y)
		var direccion := (_hilo[i] - _hilo[i - 1]).normalized()
		var lado := direccion.orthogonal() * (1.0 if azar.randf() < 0.5 else -1.0)
		# Solo en el hilo grueso; en el fino ensuciarían las letras pequeñas.
		if _tramo_de(i) == Tramo.GRUESO:
			_pelusas.append([_hilo[i], lado.rotated(azar.randf_range(-0.6, 0.6)), _largos[i]])


func _largo_en(punto: Vector2, desde: float = 0.0, hasta: float = INF) -> float:
	var mejor := -1
	for i in _hilo.size():
		if _largos[i] < desde or _largos[i] > hasta:
			continue
		if (
			mejor < 0
			or _hilo[i].distance_squared_to(punto) < _hilo[mejor].distance_squared_to(punto)
		):
			mejor = i
	return _largos[maxi(mejor, 0)]


func _tramo_de(i: int) -> Tramo:
	for tramo: Array in _tramos:
		if i >= tramo[0] and i <= tramo[1]:
			return tramo[2]
	return Tramo.GRUESO


func _dibujar() -> void:
	_dibujar_collar()
	if _hilo.is_empty() or _largo_visible <= 0.0:
		return
	var visible := PackedVector2Array()
	for i in _hilo.size():
		if _largos[i] > _largo_visible:
			var t := inverse_lerp(_largos[i - 1], _largos[i], _largo_visible)
			visible.append(_hilo[i - 1].lerp(_hilo[i], t))
			break
		visible.append(_hilo[i])
	if visible.size() < 2:
		return
	_dibujar_tramos(visible)
	for pelusa: Array in _pelusas:
		if pelusa[2] <= _largo_visible:
			var desde: Vector2 = pelusa[0] + pelusa[1] * 2.0
			_pincel.draw_line(desde, desde + pelusa[1] * 2.0, COLOR_HILO, 1.0)
	for suelto: Array in _sueltos:
		if suelto[1] <= _largo_visible:
			_dibujar_trazo_suelto(suelto[0], suelto[2])
	_dibujar_punta(visible)


func _dibujar_punta(visible: PackedVector2Array) -> void:
	var punta := visible[-1]
	if _tramo_de(visible.size() - 1) == Tramo.OCULTO:
		return
	if _anudado:
		_pincel.draw_circle(punta, 3.0, COLOR_CONTORNO)
		_pincel.draw_circle(punta, 2.0, COLOR_HILO)
		_pincel.draw_line(punta, punta + Vector2(3, 4), COLOR_HILO, 1.0)
		_pincel.draw_line(punta, punta + Vector2(5, -1), COLOR_HILO, 1.0)
	elif _con_aguja:
		var direccion := (visible[-1] - visible[-2]).normalized()
		var hasta := punta + direccion * LARGO_DE_LA_AGUJA
		_pincel.draw_line(punta - direccion * 2.0, hasta, COLOR_CONTORNO, 3.0)
		_pincel.draw_line(punta - direccion * 1.0, hasta, COLOR_AGUJA, 1.0)


func _dibujar_tramos(visible: PackedVector2Array) -> void:
	var tramos := _tramos if not _tramos.is_empty() else [[0, _hilo.size() - 1, Tramo.GRUESO]]
	for tramo: Array in tramos:
		if tramo[2] == Tramo.OCULTO or tramo[0] >= visible.size() - 1:
			continue
		var parte := visible.slice(tramo[0], mini(tramo[1] + 1, visible.size()))
		if parte.size() < 2:
			continue
		if tramo[2] == Tramo.GRUESO:
			_pincel.draw_polyline(parte, COLOR_CONTORNO, 5.0)
			_pincel.draw_polyline(parte, COLOR_HILO, 3.0)
			_pincel.draw_polyline(_desplazar(parte, Vector2(0, -1)), COLOR_BRILLO_HILO, 1.0)
			continue
		_pincel.draw_polyline(parte, COLOR_CONTORNO, 4.0)
		_pincel.draw_polyline(parte, COLOR_HILO, 2.0)


func _dibujar_trazo_suelto(trazo: PackedVector2Array, tipo: Tramo = Tramo.GRUESO) -> void:
	var grueso := tipo == Tramo.GRUESO
	if trazo.size() == 1:
		_pincel.draw_circle(trazo[0], 2.5 if grueso else 2.0, COLOR_CONTORNO)
		_pincel.draw_circle(trazo[0], 1.5 if grueso else 1.0, COLOR_HILO)
		return
	_pincel.draw_polyline(trazo, COLOR_CONTORNO, 5.0 if grueso else 4.0)
	_pincel.draw_polyline(trazo, COLOR_HILO, 3.0 if grueso else 2.0)


func _dibujar_collar() -> void:
	if _collar_visible <= 0.0:
		return
	var transparencia := Color(1, 1, 1, _collar_visible)
	var anillo := PackedVector2Array()
	for i in 33:
		var angulo := TAU * i / 32.0
		anillo.append(_collar_centro + Vector2(cos(angulo) * 14.0, sin(angulo) * 6.0))
	_pincel.draw_polyline(anillo, COLOR_CONTORNO * transparencia, 7.0)
	_pincel.draw_polyline(anillo, COLOR_CUERO * transparencia, 5.0)
	_pincel.draw_polyline(
		_desplazar(anillo.slice(17, 33), Vector2(0, -1)), COLOR_CUERO_CLARO * transparencia, 1.0
	)
	for i in range(0, 32, 3):
		_pincel.draw_rect(
			Rect2(anillo[i] - Vector2(0.5, 0.5), Vector2.ONE), COLOR_HILO * transparencia
		)
	_pincel.draw_circle(_chapita, 5.0, COLOR_CONTORNO * transparencia)
	_pincel.draw_circle(_chapita, 4.0, COLOR_CHAPITA * transparencia)
	_pincel.draw_rect(
		Rect2(_chapita + Vector2(-2, -2), Vector2(2, 1)), COLOR_CHAPITA_CLARA * transparencia
	)


func _desplazar(puntos: PackedVector2Array, cuanto: Vector2) -> PackedVector2Array:
	var movidos := PackedVector2Array()
	for punto in puntos:
		movidos.append(punto + cuanto)
	return movidos
