# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name Pesadilla
extends CanvasLayer
## Bordes oscuros que se cierran sobre la pantalla cuando algo amenaza a Lino.

const AyudasDeEscena = preload("ayudas_de_escena.gd")

const SHADER: Shader = preload("../shaders/pesadilla.gdshader")
const GRUPO_SOMBRAS: StringName = &"guard_enemy"
const ESTADOS_EN_LA_MIRA: Array[int] = [Guard.State.DETECTING, Guard.State.ALERTED]

var grupos: Array[StringName] = [GRUPO_SOMBRAS]
var amenazas: Array[Node2D] = []
var inofensivos: Array[Node] = []
var distancia_inicio: float = 520.0
var distancia_maxima: float = 170.0
var intensidad_maxima: float = 0.8
var intensidad_en_la_mira: float = 1.0
var intensidad_fija: float = -1.0
var velocidad_entrada: float = 1.8
var velocidad_salida: float = 0.6
var velocidad_salida_en_pausa: float = 3.0

var intensidad: float = 0.0
var material: ShaderMaterial


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 1
	material = ShaderMaterial.new()
	material.shader = SHADER
	var velo := AyudasDeEscena.rect_de_pantalla_completa()
	velo.material = material
	add_child(velo)
	_ir_debajo_de_la_interfaz.call_deferred()


func _ir_debajo_de_la_interfaz() -> void:
	# Este CanvasLayer tiene la misma capa de dibujo que la interfaz, así que solo el orden
	# entre los nodos de la raíz decide cuál queda encima
	var nivel := get_parent()
	var raiz := get_tree().root
	if not nivel or nivel == raiz:
		return
	nivel.tree_exiting.connect(queue_free)
	reparent(raiz)
	raiz.move_child(self, 0)


func _process(delta: float) -> void:
	var objetivo := intensidad_fija if intensidad_fija >= 0.0 else _medir_amenaza()
	var velocidad := velocidad_entrada if objetivo > intensidad else velocidad_salida
	if get_tree().paused:
		objetivo = 0.0
		velocidad = velocidad_salida_en_pausa
	intensidad = move_toward(intensidad, objetivo, velocidad * delta)
	material.set_shader_parameter("intensidad", intensidad)


func _medir_amenaza() -> float:
	var lino := get_tree().get_first_node_in_group("player") as Node2D
	if not lino:
		return 0.0
	var mas_cerca := INF
	for grupo in grupos:
		for sombra in get_tree().get_nodes_in_group(grupo):
			if not (sombra is Node2D) or not sombra.is_visible_in_tree() or sombra in inofensivos:
				continue
			if sombra.process_mode == Node.PROCESS_MODE_DISABLED:
				continue
			if sombra is Guard and (sombra as Guard).state in ESTADOS_EN_LA_MIRA:
				return intensidad_en_la_mira
			mas_cerca = minf(mas_cerca, lino.global_position.distance_to(sombra.global_position))
	for amenaza in amenazas:
		if is_instance_valid(amenaza):
			mas_cerca = minf(mas_cerca, lino.global_position.distance_to(amenaza.global_position))
	var cercania := 1.0 - smoothstep(distancia_maxima, distancia_inicio, mas_cerca)
	return cercania * intensidad_maxima
