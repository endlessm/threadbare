# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

const DISTANCIA_LADRIDO_DE_LUTO: float = 520.0
const DURACION_LADRIDO_DE_LUTO: float = 1.6
const DURACION_CARRERA_DE_LUTO: float = 2.0
const MAXIMO_DE_LADRIDOS: int = 2
const VELOCIDAD_DE_LINO: float = 80.0
const DISTANCIA_DE_PARADA: float = 5.0
const NOMBRE_DEL_JUGADOR: String = "Player"
const GRUPO_PUERTA: StringName = &"puerta_cinematica"
const METODO_ABRIR_PUERTA: StringName = &"abrir_puerta_secreta"
const ANIM_CAMINAR: StringName = &"walk"
const ANIM_QUIETO: StringName = &"idle"
const ANIM_LADRAR: StringName = &"bark"

@export var punto_parada_lino: Marker2D
@export var posicion_junto_a_lazaro: Marker2D

var secuencia_activada: bool = false
var luto_ya_ladro: bool = false

@onready var jugador: CharacterBody2D = $OnTheGround/Player
@onready var sprite_jugador: AnimatedSprite2D = jugador.get_node("%PlayerSprite")
@onready var luto: CharacterBody2D = $OnTheGround/Luto
@onready var luto_sprite: AnimatedSprite2D = $OnTheGround/Luto/AnimatedSprite2D
@onready var cinematica: Cinematic = $Cinematic
@onready var detector_dialogo: Area2D = $OnTheGround/DetectorDialogo


func _ready() -> void:
	# la cinemática la lanza _comenzar_secuencia, no su autostart
	cinematica.autostart = false

	luto.add_child(EfectoFantasma.new())

	_luto_corre()


func _process(_delta: float) -> void:
	if luto_ya_ladro or secuencia_activada:
		return
	var distancia := jugador.global_position.distance_to(_centro_del_detector())
	if distancia < DISTANCIA_LADRIDO_DE_LUTO:
		luto_ya_ladro = true
		_luto_ladra()


# el nodo del detector puede estar lejos de su forma de colisión, que es la zona real
func _centro_del_detector() -> Vector2:
	for hijo in detector_dialogo.get_children():
		if hijo is CollisionShape2D:
			return hijo.global_position
	return detector_dialogo.global_position


func _luto_ladra() -> void:
	Ladrido.sonar(self, luto.global_position, MAXIMO_DE_LADRIDOS)
	if not luto_sprite.sprite_frames.has_animation(ANIM_LADRAR):
		return
	if luto_sprite.animation == ANIM_CAMINAR:
		return
	luto_sprite.play(ANIM_LADRAR)
	await get_tree().create_timer(DURACION_LADRIDO_DE_LUTO).timeout
	if is_instance_valid(luto_sprite) and luto_sprite.animation == ANIM_LADRAR:
		luto_sprite.play(ANIM_QUIETO)


func _luto_corre() -> void:
	luto_sprite.play(ANIM_CAMINAR)

	var tween := create_tween()
	tween.tween_property(
		luto, "global_position", posicion_junto_a_lazaro.global_position, DURACION_CARRERA_DE_LUTO
	)
	await tween.finished

	luto_sprite.play(ANIM_QUIETO)


func _on_detector_dialogo_body_entered(body: Node2D) -> void:
	if body.name == NOMBRE_DEL_JUGADOR and not secuencia_activada:
		secuencia_activada = true
		_comenzar_secuencia()


func _comenzar_secuencia() -> void:
	if jugador.has_method("take_control"):
		jugador.take_control(self)

	jugador.velocity = Vector2.ZERO
	await get_tree().physics_frame

	await _llevar_a_lino_al_punto_de_parada()

	# Mira a la derecha, hacia Luto: el sprite solo cambia de lado al moverse.
	sprite_jugador.play(ANIM_QUIETO)
	sprite_jugador.flip_h = false

	var bloqueo := BloqueoSaltoDialogo.new()
	add_child(bloqueo)
	cinematica.start()
	await cinematica.cinematic_finished
	bloqueo.queue_free()

	_abrir_puerta_secreta()

	if jugador.has_method("return_control"):
		jugador.return_control(self)


func _llevar_a_lino_al_punto_de_parada() -> void:
	var destino := punto_parada_lino.global_position
	while jugador.global_position.distance_to(destino) > DISTANCIA_DE_PARADA:
		var direccion := (destino - jugador.global_position).normalized()

		jugador.velocity = direccion * VELOCIDAD_DE_LINO
		jugador.move_and_slide()

		if sprite_jugador.animation != ANIM_CAMINAR:
			sprite_jugador.play(ANIM_CAMINAR)

		await get_tree().physics_frame

	jugador.velocity = Vector2.ZERO


func _abrir_puerta_secreta() -> void:
	var puerta := get_tree().get_first_node_in_group(GRUPO_PUERTA)
	if puerta == null:
		push_error("No se encontró la puerta.")
	elif puerta.has_method(METODO_ABRIR_PUERTA):
		puerta.call(METODO_ABRIR_PUERTA)
	else:
		push_error("El nodo encontrado no tiene la función abrir_puerta_secreta")
