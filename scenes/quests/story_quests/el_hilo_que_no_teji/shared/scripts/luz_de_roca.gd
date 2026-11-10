# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node
## Luz de las rocas de un puzzle de secuencia.
##
## Cada roca se enciende con el color de su piedra cuando suena (en la demostración o al tocarla)
## y la luz se desvanece despacio. Al tocarla, además, el puzzle dice si fue acierto o error, y
## eso no depende del color: el acierto lanza un anillo que se expande y el error uno que se
## encoge hacia la roca mientras la piedra tiembla. Así se distingue aunque no se vean los colores.
## No toca ningún archivo del juego base: solo escucha las señales de las rocas.

const AyudasDeEscena = preload("ayudas_de_escena.gd")

enum Veredicto { NEUTRO, ACIERTO, PASO_COMPLETO, ERROR }

const TAMANO_TEXTURA_HALO: int = 128
const TAMANO_TEXTURA_ANILLO: int = 128
const GROSOR_DEL_ANILLO: float = 0.14
const POSICION_DE_LA_LUZ := Vector2(0, -14)

const ESCALA_DEL_HALO: float = 1.6
const BRILLO_DEL_HALO: float = 0.9
const BLANCO_EN_EL_COLOR: float = 0.45
const ATAQUE_DE_LA_LUZ: float = 0.06
const DESVANECIDO_SOBRE_LA_DURACION: float = 0.95

const COLOR_ACIERTO := Color(1.0, 0.88, 0.5)
const ESCALA_ANILLO_INICIAL: float = 0.5
const ESCALA_ANILLO_ACIERTO: float = 1.9
const ESCALA_ANILLO_PASO_COMPLETO: float = 3.0
const DURACION_ANILLO_ACIERTO: float = 0.45
const DURACION_ANILLO_PASO_COMPLETO: float = 0.9

const COLOR_ERROR := Color(0.55, 0.5, 0.8)
const ESCALA_ANILLO_ERROR_INICIAL: float = 2.0
const ESCALA_ANILLO_ERROR_FINAL: float = 0.35
const DURACION_ANILLO_ERROR: float = 0.35
const OPACIDAD_DEL_ANILLO: float = 0.9
const TEMBLOR_DE_ERROR: float = 5.0
const SACUDIDAS_DE_ERROR: int = 3
const DURACION_SACUDIDA: float = 0.05

## Cuánto se agranda la zona donde Lino puede pulsar Space sobre la roca.
const FACTOR_ZONA_DE_INTERACCION: float = 1.8

static var _textura_anillo: ImageTexture

var _puzzle: SequencePuzzle
var _paso_actual: int = 0
var _posicion: int = 0
var _textura_halo: GradientTexture2D
var _suma: CanvasItemMaterial
var _halos: Dictionary = {}
var _anillos: Dictionary = {}
var _animaciones: Dictionary = {}
var _ultimo_cuadro: Dictionary = {}


func vigilar(puzzle: SequencePuzzle) -> void:
	_puzzle = puzzle
	_paso_actual = puzzle.get_progress()
	_textura_halo = AyudasDeEscena.textura_de_halo(TAMANO_TEXTURA_HALO)
	_suma = AyudasDeEscena.material_de_suma()

	var objetos := puzzle.get_node_or_null("Objects")
	if not objetos:
		return
	for hijo in objetos.get_children():
		if hijo is SequencePuzzleObject:
			_preparar_roca(hijo)
	# Las fogatas del letrero (donde Lino pulsa Space para ver la demostración).
	for paso in puzzle.steps:
		if paso.hint_sign and paso.hint_sign.interact_area:
			_agrandar_zona_de_interaccion(paso.hint_sign.interact_area)


func _preparar_roca(roca: SequencePuzzleObject) -> void:
	_halos[roca] = _crear_luz(roca, _textura_halo)
	_anillos[roca] = _crear_luz(roca, textura_de_anillo())
	roca.animated_sprite.animation_changed.connect(_al_cambiar_animacion.bind(roca))
	roca.kicked.connect(_al_tocar.bind(roca))
	_agrandar_zona_de_interaccion(roca.interact_area)


func _crear_luz(roca: SequencePuzzleObject, textura: Texture2D) -> Sprite2D:
	var luz := Sprite2D.new()
	luz.texture = textura
	luz.material = _suma
	luz.position = POSICION_DE_LA_LUZ
	luz.modulate = Color(1, 1, 1, 0)
	roca.add_child(luz)
	return luz


func _agrandar_zona_de_interaccion(area: InteractArea) -> void:
	# Las formas son recursos compartidos por todas las instancias: se duplican para no agrandar otras.
	for hijo in area.get_children():
		if not hijo is CollisionShape2D:
			continue
		if hijo.shape is RectangleShape2D:
			var rectangulo: RectangleShape2D = hijo.shape.duplicate()
			rectangulo.size *= FACTOR_ZONA_DE_INTERACCION
			hijo.shape = rectangulo
		elif hijo.shape is CircleShape2D:
			var circulo: CircleShape2D = hijo.shape.duplicate()
			circulo.radius *= FACTOR_ZONA_DE_INTERACCION
			hijo.shape = circulo


func _al_cambiar_animacion(roca: SequencePuzzleObject) -> void:
	if roca.animated_sprite.animation == &"struck":
		_encender(roca)


func _al_tocar(roca: SequencePuzzleObject) -> void:
	_encender(roca)
	match _evaluar(roca):
		Veredicto.ACIERTO:
			_lanzar_anillo_de_acierto(roca, ESCALA_ANILLO_ACIERTO, DURACION_ANILLO_ACIERTO)
		Veredicto.PASO_COMPLETO:
			_lanzar_anillo_de_acierto(
				roca, ESCALA_ANILLO_PASO_COMPLETO, DURACION_ANILLO_PASO_COMPLETO
			)
		Veredicto.ERROR:
			_lanzar_anillo_de_error(roca)
			_sacudir(roca)


## Repite la lógica del puzzle para saber si el toque fue correcto.
func _evaluar(roca: SequencePuzzleObject) -> Veredicto:
	if _paso_actual >= _puzzle.steps.size():
		return Veredicto.NEUTRO
	var secuencia := _puzzle.steps[_paso_actual].sequence
	if _posicion != 0 and secuencia[_posicion] != roca:
		_posicion = 0
	if secuencia[_posicion] != roca:
		return Veredicto.ERROR
	_posicion += 1
	if _posicion < secuencia.size():
		return Veredicto.ACIERTO
	_posicion = 0
	_paso_actual += 1
	return Veredicto.PASO_COMPLETO


func _encender(roca: SequencePuzzleObject) -> void:
	var cuadro := Engine.get_process_frames()
	if _ultimo_cuadro.get(roca, -1) == cuadro:
		return
	_ultimo_cuadro[roca] = cuadro

	var halo: Sprite2D = _halos[roca]
	var color := roca.sprite_modulate.lerp(Color.WHITE, BLANCO_EN_EL_COLOR)
	halo.scale = Vector2.ONE * ESCALA_DEL_HALO
	halo.modulate = Color(color, 0.0)

	var animacion := _nueva_animacion(halo)
	animacion.tween_property(halo, "modulate:a", BRILLO_DEL_HALO, ATAQUE_DE_LA_LUZ)
	animacion.tween_property(
		halo, "modulate:a", 0.0, roca.strike_duration * DESVANECIDO_SOBRE_LA_DURACION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _lanzar_anillo_de_acierto(roca: SequencePuzzleObject, escala_final: float, duracion: float) -> void:
	var anillo: Sprite2D = _anillos[roca]
	anillo.scale = Vector2.ONE * ESCALA_ANILLO_INICIAL
	anillo.modulate = Color(COLOR_ACIERTO, OPACIDAD_DEL_ANILLO)

	var animacion := _nueva_animacion(anillo)
	animacion.set_parallel(true)
	animacion.tween_property(anillo, "scale", Vector2.ONE * escala_final, duracion).set_trans(
		Tween.TRANS_CUBIC
	).set_ease(Tween.EASE_OUT)
	animacion.tween_property(anillo, "modulate:a", 0.0, duracion)


func _lanzar_anillo_de_error(roca: SequencePuzzleObject) -> void:
	var anillo: Sprite2D = _anillos[roca]
	anillo.scale = Vector2.ONE * ESCALA_ANILLO_ERROR_INICIAL
	anillo.modulate = Color(COLOR_ERROR, OPACIDAD_DEL_ANILLO)

	var animacion := _nueva_animacion(anillo)
	animacion.set_parallel(true)
	animacion.tween_property(
		anillo, "scale", Vector2.ONE * ESCALA_ANILLO_ERROR_FINAL, DURACION_ANILLO_ERROR
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	animacion.tween_property(anillo, "modulate:a", 0.0, DURACION_ANILLO_ERROR)


func _sacudir(roca: SequencePuzzleObject) -> void:
	var piedra := roca.animated_sprite
	var sacudida := piedra.create_tween()
	for i in SACUDIDAS_DE_ERROR:
		var lado := TEMBLOR_DE_ERROR if i % 2 == 0 else -TEMBLOR_DE_ERROR
		sacudida.tween_property(piedra, "offset:x", lado, DURACION_SACUDIDA)
	sacudida.tween_property(piedra, "offset:x", 0.0, DURACION_SACUDIDA)


## Cancela la animación anterior de esa luz para que no se pisen si se toca varias veces seguidas.
func _nueva_animacion(luz: Sprite2D) -> Tween:
	var anterior: Tween = _animaciones.get(luz)
	if anterior and anterior.is_valid():
		anterior.kill()
	var nueva := luz.create_tween()
	_animaciones[luz] = nueva
	return nueva


## Anillo suave en blanco, para teñir y usar con el material de suma. Se crea una sola vez.
static func textura_de_anillo() -> ImageTexture:
	if not _textura_anillo:
		_textura_anillo = _crear_textura_de_anillo()
	return _textura_anillo


static func _crear_textura_de_anillo() -> ImageTexture:
	var imagen := Image.create(
		TAMANO_TEXTURA_ANILLO, TAMANO_TEXTURA_ANILLO, false, Image.FORMAT_RGBA8
	)
	var centro := (TAMANO_TEXTURA_ANILLO - 1) / 2.0
	var radio := TAMANO_TEXTURA_ANILLO / 2.0
	for y in TAMANO_TEXTURA_ANILLO:
		for x in TAMANO_TEXTURA_ANILLO:
			var distancia := Vector2(x - centro, y - centro).length() / radio
			var opacidad := clampf(1.0 - absf(distancia - 0.8) / GROSOR_DEL_ANILLO, 0.0, 1.0)
			imagen.set_pixel(x, y, Color(1, 1, 1, opacidad * opacidad))
	return ImageTexture.create_from_image(imagen)
