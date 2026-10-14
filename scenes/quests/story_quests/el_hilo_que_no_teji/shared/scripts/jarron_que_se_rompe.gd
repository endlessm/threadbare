# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends FillingBarrel
## Jarrón que, al llenarse, se rompe en vez de crecer y desvanecerse.

const ANIMACION_ROTURA: StringName = &"shatter"
## sfx_barrel_breaking.tres
const SONIDO_ROTURA: AudioStream = preload("uid://c3iuv5ax8i78v")
const DestelloDeAcierto = preload("destello_de_acierto.gd")
const CENTRO_DEL_JARRON := Vector2(0, -24)

## Cada vez que el jarrón recibe un orbe, llene o no. El nivel lo usa para saber que Lino avanza.
signal orbe_recibido


func increment(by: int = 1) -> void:
	if is_locked or _amount >= needed_amount:
		return
	animation_player.play(&"increment")
	_amount += by
	orbe_recibido.emit()
	if not Engine.is_editor_hint():
		# cuelga del padre para que siga vivo cuando el jarrón se rompa y se libere
		DestelloDeAcierto.lanzar(
			get_parent(), global_position + CENTRO_DEL_JARRON, _amount >= needed_amount
		)
	animated_sprite_2d.frame = floor(float(_amount) / needed_amount * _total_frames())
	if _amount < needed_amount:
		return

	_disable_collisions.call_deferred()
	await animation_player.animation_finished
	await _romperse()
	queue_free()
	completed.emit()


func _romperse() -> void:
	if not animated_sprite_2d.sprite_frames.has_animation(ANIMACION_ROTURA):
		animation_player.play(&"completed")
		await animation_player.animation_finished
		return

	_sonar_rotura()
	animated_sprite_2d.play(ANIMACION_ROTURA)
	await animated_sprite_2d.animation_finished


## El sonido cuelga del padre para que no se corte cuando el jarrón desaparece.
func _sonar_rotura() -> void:
	var sonido := AudioStreamPlayer2D.new()
	sonido.stream = SONIDO_ROTURA
	sonido.bus = &"SFX"
	get_parent().add_child(sonido)
	sonido.global_position = global_position
	sonido.finished.connect(sonido.queue_free)
	sonido.play()
