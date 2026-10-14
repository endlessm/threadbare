# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends RefCounted
## Destello dorado de acierto: un halo que se desvanece y un anillo que se expande hacia afuera.
## Es el mismo lenguaje que las rocas del nivel 2: dorado que se expande significa "bien".
## La versión grande suma un segundo anillo y motas que suben.

const AyudasDeEscena = preload("ayudas_de_escena.gd")
const LuzDeRoca = preload("luz_de_roca.gd")

const COLOR := Color(1.0, 0.88, 0.5)
const Z_INDEX_DEL_DESTELLO: int = 30
const TAMANO_TEXTURA_HALO: int = 128

const ESCALA_HALO_NORMAL: float = 1.4
const ESCALA_HALO_GRANDE: float = 2.4
const BRILLO_NORMAL: float = 0.8
const BRILLO_GRANDE: float = 1.0
const ATAQUE: float = 0.06
const DESVANECIDO_NORMAL: float = 0.55
const DESVANECIDO_GRANDE: float = 1.0

const ESCALA_ANILLO_INICIAL: float = 0.5
const ESCALA_ANILLO_NORMAL: float = 1.8
const DURACION_ANILLO_NORMAL: float = 0.5
const ESCALA_ANILLO_GRANDE: float = 3.4
const DURACION_ANILLO_GRANDE: float = 1.0
const ESCALA_SEGUNDO_ANILLO: float = 2.4
const DURACION_SEGUNDO_ANILLO: float = 0.8
const RETRASO_SEGUNDO_ANILLO: float = 0.15
const OPACIDAD_ANILLO: float = 0.9

const CANTIDAD_DE_MOTAS: int = 24
const VIDA_DE_LAS_MOTAS: float = 1.3
const RADIO_DE_EMISION: float = 22.0
const DISPERSION_DE_LAS_MOTAS: float = 60.0
const GRAVEDAD_DE_LAS_MOTAS := Vector2(0, -30)
const VELOCIDAD_MINIMA_DE_LAS_MOTAS: float = 30.0
const VELOCIDAD_MAXIMA_DE_LAS_MOTAS: float = 80.0
const TAMANO_MINIMO_DE_LAS_MOTAS: float = 3.0
const TAMANO_MAXIMO_DE_LAS_MOTAS: float = 6.0


## Lanza el destello en una posición del mundo. Cuelga de [param donde], que debe seguir
## vivo después de que el objeto que lo provoca desaparezca (por ejemplo, su padre).
static func lanzar(donde: Node, posicion: Vector2, grande: bool = false) -> void:
	var raiz := Node2D.new()
	raiz.top_level = true
	raiz.z_index = Z_INDEX_DEL_DESTELLO
	donde.add_child(raiz)
	raiz.global_position = posicion

	var suma := AyudasDeEscena.material_de_suma()
	var halo := _crear_luz(AyudasDeEscena.textura_de_halo(TAMANO_TEXTURA_HALO), suma, raiz)
	var anillo := _crear_luz(LuzDeRoca.textura_de_anillo(), suma, raiz)
	halo.scale = Vector2.ONE * (ESCALA_HALO_GRANDE if grande else ESCALA_HALO_NORMAL)
	var brillo: float = BRILLO_GRANDE if grande else BRILLO_NORMAL
	var desvanecido: float = DESVANECIDO_GRANDE if grande else DESVANECIDO_NORMAL
	var escala_anillo: float = ESCALA_ANILLO_GRANDE if grande else ESCALA_ANILLO_NORMAL
	var duracion_anillo: float = DURACION_ANILLO_GRANDE if grande else DURACION_ANILLO_NORMAL
	var duracion_total: float = maxf(desvanecido, duracion_anillo)

	var animacion := raiz.create_tween().set_parallel(true)
	animacion.tween_property(halo, "modulate:a", brillo, ATAQUE)
	animacion.tween_property(halo, "modulate:a", 0.0, desvanecido).set_delay(ATAQUE).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_OUT)
	_expandir(animacion, anillo, escala_anillo, duracion_anillo, 0.0)

	if grande:
		var segundo := _crear_luz(LuzDeRoca.textura_de_anillo(), suma, raiz)
		_expandir(animacion, segundo, ESCALA_SEGUNDO_ANILLO, DURACION_SEGUNDO_ANILLO, RETRASO_SEGUNDO_ANILLO)
		duracion_total = maxf(duracion_total, RETRASO_SEGUNDO_ANILLO + DURACION_SEGUNDO_ANILLO)
		raiz.add_child(_crear_motas(suma))
		duracion_total = maxf(duracion_total, VIDA_DE_LAS_MOTAS)

	animacion.tween_callback(raiz.queue_free).set_delay(duracion_total)


static func _crear_luz(textura: Texture2D, material: CanvasItemMaterial, padre: Node2D) -> Sprite2D:
	var luz := Sprite2D.new()
	luz.texture = textura
	luz.material = material
	luz.modulate = Color(COLOR, 0.0)
	padre.add_child(luz)
	return luz


static func _expandir(
	animacion: Tween, anillo: Sprite2D, escala_final: float, duracion: float, retraso: float
) -> void:
	anillo.scale = Vector2.ONE * ESCALA_ANILLO_INICIAL
	animacion.tween_property(anillo, "modulate:a", OPACIDAD_ANILLO, 0.01).set_delay(retraso)
	animacion.tween_property(anillo, "scale", Vector2.ONE * escala_final, duracion).set_delay(
		retraso
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	animacion.tween_property(anillo, "modulate:a", 0.0, duracion).set_delay(retraso + 0.01)


static func _crear_motas(material: CanvasItemMaterial) -> CPUParticles2D:
	var motas := CPUParticles2D.new()
	motas.material = material
	motas.amount = CANTIDAD_DE_MOTAS
	motas.lifetime = VIDA_DE_LAS_MOTAS
	motas.one_shot = true
	motas.explosiveness = 0.9
	motas.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	motas.emission_sphere_radius = RADIO_DE_EMISION
	motas.direction = Vector2.UP
	motas.spread = DISPERSION_DE_LAS_MOTAS
	motas.gravity = GRAVEDAD_DE_LAS_MOTAS
	motas.initial_velocity_min = VELOCIDAD_MINIMA_DE_LAS_MOTAS
	motas.initial_velocity_max = VELOCIDAD_MAXIMA_DE_LAS_MOTAS
	motas.scale_amount_min = TAMANO_MINIMO_DE_LAS_MOTAS
	motas.scale_amount_max = TAMANO_MAXIMO_DE_LAS_MOTAS
	motas.color = COLOR
	motas.emitting = true
	return motas
