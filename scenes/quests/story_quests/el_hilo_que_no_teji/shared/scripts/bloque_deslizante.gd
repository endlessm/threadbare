# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Area2D
## Bloque que se desliza de un lado a otro y deshace los proyectiles.

## void_particles.tscn: las nubes de polvo oscuro del vacío que persigue.
const PARTICULAS_VACIO: PackedScene = preload("uid://s2ohp10ssq7l")
## particles_canvasgroup_outline.gdshader: el borde blanco de esas nubes.
const BORDE_VACIO: Shader = preload("uid://dvyec12fgsuta")
const RADIO_MINIVACIO: float = 14.0
const ESCALA_NUBES_MINIVACIO: float = 0.45
const VELOCIDAD_NUBES := Vector2(4.0, 12.0)
const CANTIDAD_DE_NUBES: int = 40
const GROSOR_DEL_BORDE: float = 2.0
const MARGEN_DEL_CHOQUE: float = 10.0

@export var recorrido: Vector2 = Vector2(0, 160)
@export_range(0.2, 10.0, 0.1, "suffix:s") var segundos_por_recorrido: float = 2.0
@export_range(0.0, 5.0, 0.1, "suffix:s") var pausa_en_extremos: float = 0.4
@export_range(0.0, 10.0, 0.1, "suffix:s") var espera_inicial: float = 0.0

@onready var _dibujo: Sprite2D = $Sprite2D
@onready var _choque: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	body_entered.connect(_al_tocar)
	var origen := position
	_crear_minivacio()
	if espera_inicial > 0.0:
		await get_tree().create_timer(espera_inicial).timeout
	_empezar_vaiven(origen)


func _empezar_vaiven(origen: Vector2) -> void:
	var vaiven := create_tween().set_loops()
	for destino in [origen + recorrido, origen]:
		var tramo := vaiven.tween_property(self, "position", destino, segundos_por_recorrido)
		tramo.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		vaiven.tween_interval(pausa_en_extremos)


func _crear_minivacio() -> void:
	_dibujo.hide()
	var grupo := CanvasGroup.new()
	var borde := ShaderMaterial.new()
	borde.shader = BORDE_VACIO
	borde.set_shader_parameter("outline_color", Color.WHITE)
	borde.set_shader_parameter("thickness", GROSOR_DEL_BORDE)
	grupo.material = borde
	add_child(grupo)
	grupo.add_child(_crear_nubes())
	var forma := CircleShape2D.new()
	forma.radius = RADIO_MINIVACIO + MARGEN_DEL_CHOQUE
	_choque.shape = forma


func _crear_nubes() -> GPUParticles2D:
	var nubes := PARTICULAS_VACIO.instantiate() as GPUParticles2D
	var proceso := nubes.process_material.duplicate() as ParticleProcessMaterial
	proceso.emission_sphere_radius = RADIO_MINIVACIO
	proceso.radial_velocity_min = VELOCIDAD_NUBES.x
	proceso.radial_velocity_max = VELOCIDAD_NUBES.y
	proceso.scale_min *= ESCALA_NUBES_MINIVACIO
	proceso.scale_max *= ESCALA_NUBES_MINIVACIO
	nubes.process_material = proceso
	nubes.one_shot = false
	nubes.local_coords = true
	nubes.explosiveness = 0.0
	nubes.amount = CANTIDAD_DE_NUBES
	nubes.emitting = true
	return nubes


func _al_tocar(cuerpo: Node2D) -> void:
	if cuerpo.is_in_group("projectiles") and cuerpo.has_method("explode"):
		cuerpo.explode.call_deferred()
