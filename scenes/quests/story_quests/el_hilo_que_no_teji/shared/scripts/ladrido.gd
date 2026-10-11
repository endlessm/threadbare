# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name Ladrido
extends RefCounted
## Ladridos de Luto/Manchitas con variación de sonido, tono y volumen.

const SONIDOS: Array[AudioStream] = [
	preload("uid://48bp1av30u6w"),
	preload("uid://dkioepw7f5ejj"),
	preload("uid://bf1ptifdmuyoc"),
	preload("uid://cdgv2b0mq1not"),
	preload("uid://c7mgvsoj3pid6"),
	preload("uid://bex8i3c57ruar"),
	preload("uid://6vfe7ntcmxjf"),
]
const PESOS_RAFAGA: Array[float] = [0.45, 0.35, 0.2]
const PAUSA_EN_RAFAGA := Vector2(0.3, 1.1)
const DISTANCIA_MAXIMA: float = 5000.0
const ATENUACION: float = 0.5
const TONO := Vector2(0.9, 1.1)
const VOLUMEN_DB := Vector2(-3.0, 0.0)

static var _ultimo_sonido: AudioStream


static func sonar(padre: Node, posicion: Vector2, maximo: int = 3) -> void:
	var cantidad: int = mini(_cantidad_de_ladridos(), maximo)
	for i in cantidad:
		if i > 0:
			var pausa := randf_range(PAUSA_EN_RAFAGA.x, PAUSA_EN_RAFAGA.y)
			await padre.get_tree().create_timer(pausa).timeout
			if not is_instance_valid(padre) or not padre.is_inside_tree():
				return
		_reproducir(padre, posicion)


static func _cantidad_de_ladridos() -> int:
	var tirada := randf()
	for i in PESOS_RAFAGA.size():
		tirada -= PESOS_RAFAGA[i]
		if tirada <= 0.0:
			return i + 1
	return 1


static func _reproducir(padre: Node, posicion: Vector2) -> void:
	var opciones := SONIDOS.filter(
		func(sonido: AudioStream) -> bool: return sonido != _ultimo_sonido
	)
	_ultimo_sonido = opciones.pick_random()

	var reproductor := AudioStreamPlayer2D.new()
	reproductor.stream = _ultimo_sonido
	reproductor.bus = &"SFX"
	reproductor.max_distance = DISTANCIA_MAXIMA
	reproductor.attenuation = ATENUACION
	reproductor.pitch_scale = randf_range(TONO.x, TONO.y)
	reproductor.volume_db = randf_range(VOLUMEN_DB.x, VOLUMEN_DB.y)
	padre.add_child(reproductor)
	reproductor.global_position = posicion
	reproductor.finished.connect(reproductor.queue_free)
	reproductor.play()
