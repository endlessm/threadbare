# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node
## Aplica el filtro de color del mundo y de Lino según los hilos recogidos.

const ONDA_HILO_VELOCIDAD: float = 140.0
const ONDA_HILO_ANCHO: float = 260.0
const ONDA_HILO_ALCANCE: float = 900.0
const ONDA_HILO_BRILLO: float = 0.5
const ONDA_HILO_COLOR: float = 0.85
const ONDA_HILO_TINTE: float = 0.7
const ONDA_APAGADA := {
	"onda_tiempo": -1.0,
	"onda_solo_cresta": false,
	"onda_alcance": 0.0,
	"onda_tinte_fuerza": 0.0,
	"onda_color_cresta": 1.0,
	"onda_brillo_cresta": 0.6,
}
const BRILLO_DEL_MUNDO: float = 0.6
const BRILLO_DE_LINO: float = 1.0

@export var material_mundo: ShaderMaterial
@export var material_jugador: ShaderMaterial

var tope_saturacion_mundo: float = 1.0


func _ready() -> void:
	if material_mundo:
		# El material se comparte entre niveles: las ondas empiezan apagadas.
		_apagar_onda_de_hilo()
		_aplicar_material_al_mundo(get_tree().current_scene)

	var lino := get_tree().get_first_node_in_group("player") as Node2D
	if lino:
		# diferido: el árbol todavía se está armando
		lino.add_child.call_deferred(BrilloDelCollar.new())


func _process(_delta: float) -> void:
	if material_mundo:
		var saturacion := minf(ElHiloQueNoTejiState.world_saturation / 100.0, tope_saturacion_mundo)
		_poner(material_mundo, "saturation", saturacion)
		_poner(material_mundo, "darkness_factor", BRILLO_DEL_MUNDO)

	if material_jugador:
		var saturacion_lino := ElHiloQueNoTejiState.player_saturation / 100.0
		_poner(material_jugador, "saturation", saturacion_lino)
		_poner(material_jugador, "darkness_factor", BRILLO_DE_LINO)


## Cambiar un parámetro de un material compartido cuesta aunque el valor sea el mismo.
func _poner(material: ShaderMaterial, parametro: StringName, valor: float) -> void:
	if material.get_shader_parameter(parametro) != valor:
		material.set_shader_parameter(parametro, valor)


func onda_de_hilo(origen: Vector2, color: Color = Color.WHITE) -> void:
	if not material_mundo or float(material_mundo.get_shader_parameter("onda_tiempo")) >= 0.0:
		return
	_poner_parametros_del_mundo(
		{
			"onda_origen": origen,
			"onda_velocidad": ONDA_HILO_VELOCIDAD,
			"onda_cantidad": 1,
			"onda_ancho": ONDA_HILO_ANCHO,
			"onda_brillo_cresta": ONDA_HILO_BRILLO,
			"onda_alcance": ONDA_HILO_ALCANCE,
			"onda_color_cresta": ONDA_HILO_COLOR,
			"onda_tinte": Color(color.r, color.g, color.b),
			"onda_tinte_fuerza": ONDA_HILO_TINTE,
			"onda_solo_cresta": true,
		}
	)

	var duracion := (ONDA_HILO_ALCANCE + ONDA_HILO_ANCHO) / ONDA_HILO_VELOCIDAD
	# Sigue aunque el juego esté en pausa por el diálogo del hilo.
	var onda := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var avance := onda.tween_property(
		material_mundo, "shader_parameter/onda_tiempo", duracion, duracion
	)
	avance.from(0.0)
	onda.tween_callback(_apagar_onda_de_hilo)


func _apagar_onda_de_hilo() -> void:
	_poner_parametros_del_mundo(ONDA_APAGADA)


func _poner_parametros_del_mundo(parametros: Dictionary) -> void:
	for nombre: String in parametros:
		material_mundo.set_shader_parameter(nombre, parametros[nombre])


func _aplicar_material_al_mundo(nodo: Node) -> void:
	if nodo.is_in_group("player") or nodo.is_in_group("ignorar_shader"):
		return
	if nodo is TileMapLayer or nodo is Sprite2D or nodo is AnimatedSprite2D:
		nodo.material = material_mundo
	for hijo in nodo.get_children():
		_aplicar_material_al_mundo(hijo)
