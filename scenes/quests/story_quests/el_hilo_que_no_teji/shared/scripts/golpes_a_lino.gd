# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name GolpesALino
extends Node
## Lo que le pasa a Lino cuando lo golpea un proyectil en los niveles 3.1 y 3.2.

## Emitida cuando un proyectil marcado como inofensivo toca a Lino.
signal golpe_inofensivo
## Emitida cuando un proyectil le hace daño a Lino.
signal golpe_con_dano

const FILTRO_GRIS: Shader = preload("uid://gg8y00eu162d")
const FRASE_PRIMER_GOLPE: String = (
	"Si sigo cargando con culpa ajena…\n" + "creo que no podré recuperarte, Manchitas..."
)
const DANO_PROYECTIL: float = 0.25
const DANO_ORBE_ELIAN: float = 1.0 / 3.0
const ORBE_ELIAN: String = "boss_projectile.tscn"
## Un proyectil con esta marca desaparece al tocar a Lino, pero no le hace daño.
const META_SIN_DANO: StringName = &"sin_dano"
const TIEMPO_INVULNERABLE: float = 2.0
const BRILLO_INVULNERABLE := Color(1.5, 1.5, 1.5, 1.0)
const TENUE_INVULNERABLE := Color(1.0, 1.0, 1.0, 0.4)
const PULSO_DE_SOMBRA: float = 0.2
const SOMBRA_DE_ELIAN := Color(0.45, 0.4, 0.6, 0.85)
const PULSO_DE_ELIAN: float = 0.4
# Los orbes de Elián suman 1/3 de gris cada uno y Lino se deshila a los 3. Con floats
# 0.333... tres veces no da exactamente 1.0, así que se compara con este margen
const MARGEN_DE_GRIS: float = 0.001
const ANIMACION_DERROTA: StringName = &"defeated"

## Lo que piensa Lino en su primer golpe. Cada nivel puede poner el suyo; vacío = no dice nada.
var frase_primer_golpe: String = FRASE_PRIMER_GOLPE
var gris: float = 0.0
var protegido: bool = false

var _jugador: Player
var _sprite: AnimatedSprite2D
var _hitbox: Area2D
var _panel_pensamiento: Control
var _material := ShaderMaterial.new()
var _invulnerable: bool = false
var _deshilado: bool = false
var _primer_golpe_recibido: bool = false


func _init(jugador: Player, panel_pensamiento: Control = null) -> void:
	_jugador = jugador
	_panel_pensamiento = panel_pensamiento
	_sprite = jugador.get_node("%PlayerSprite")
	_hitbox = jugador.get_node("PlayerHarm/HitBox")


func _ready() -> void:
	_material.shader = FILTRO_GRIS
	_sprite.material = _material
	_sprite.sprite_frames.set_animation_loop(ANIMACION_DERROTA, false)
	_hitbox.body_entered.connect(_al_recibir_proyectil)


func poner_gris(nivel: float) -> void:
	_material.set_shader_parameter("nivel_gris", nivel)


func gris_visible() -> float:
	return clampf(gris, 0.0, 1.0)


func proteger_para_siempre() -> void:
	protegido = true
	_hitbox.set_deferred("monitoring", false)
	_hitbox.set_deferred("monitorable", false)


func _al_recibir_proyectil(cuerpo: Node2D) -> void:
	if not cuerpo.is_in_group("projectiles") or _deshilado:
		return
	# diferido: no se libera un cuerpo dentro de su propia señal de física
	cuerpo.call_deferred("queue_free")
	if cuerpo.has_meta(META_SIN_DANO):
		golpe_inofensivo.emit()
		return
	if _invulnerable or protegido:
		return

	var es_orbe_elian := cuerpo.scene_file_path.ends_with(ORBE_ELIAN)
	var gris_anterior := gris_visible()
	gris += DANO_ORBE_ELIAN if es_orbe_elian else DANO_PROYECTIL
	poner_gris(gris_visible())

	golpe_con_dano.emit()
	if not _primer_golpe_recibido and is_instance_valid(_panel_pensamiento):
		_primer_golpe_recibido = true
		if frase_primer_golpe != "":
			_panel_pensamiento.mostrar_pensamiento(frase_primer_golpe)

	var se_deshila := gris >= 1.0 - MARGEN_DE_GRIS if es_orbe_elian else gris > 1.0 + MARGEN_DE_GRIS
	if se_deshila:
		_deshilado = true
		proteger_para_siempre()
		_jugador.defeat(false)
	else:
		_parpadear(gris_anterior, gris_visible(), es_orbe_elian)


func _parpadear(gris_anterior: float, gris_nuevo: float, es_orbe_elian: bool) -> void:
	_invulnerable = true
	var parpadeo := create_tween()
	if es_orbe_elian:
		_armar_parpadeo_de_orbe(parpadeo, gris_nuevo)
	else:
		_armar_parpadeo_de_sombra(parpadeo, gris_anterior, gris_nuevo)
	await get_tree().create_timer(TIEMPO_INVULNERABLE).timeout
	parpadeo.kill()
	poner_gris(gris_nuevo)
	_sprite.self_modulate = Color.WHITE
	_invulnerable = false


func _armar_parpadeo_de_orbe(parpadeo: Tween, gris_nuevo: float) -> void:
	var medio := PULSO_DE_ELIAN / 2.0
	parpadeo.set_loops(int(TIEMPO_INVULNERABLE / PULSO_DE_ELIAN))
	parpadeo.tween_method(poner_gris, gris_nuevo, 1.0, medio)
	parpadeo.parallel().tween_property(_sprite, "self_modulate", SOMBRA_DE_ELIAN, medio)
	parpadeo.tween_method(poner_gris, 1.0, gris_nuevo, medio)
	parpadeo.parallel().tween_property(_sprite, "self_modulate", Color.WHITE, medio)


func _armar_parpadeo_de_sombra(parpadeo: Tween, gris_anterior: float, gris_nuevo: float) -> void:
	var medio := PULSO_DE_SOMBRA / 2.0
	parpadeo.set_loops(int(TIEMPO_INVULNERABLE / PULSO_DE_SOMBRA))
	parpadeo.tween_callback(poner_gris.bind(gris_anterior))
	parpadeo.tween_property(_sprite, "self_modulate", BRILLO_INVULNERABLE, medio)
	parpadeo.tween_callback(poner_gris.bind(gris_nuevo))
	parpadeo.tween_property(_sprite, "self_modulate", TENUE_INVULNERABLE, medio)
