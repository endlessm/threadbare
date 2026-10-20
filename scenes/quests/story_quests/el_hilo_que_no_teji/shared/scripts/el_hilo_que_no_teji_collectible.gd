# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name StealthCollectible extends Node2D
## Fragmento de hilo que Lino recoge en el suelo.

const AyudasDeEscena = preload("ayudas_de_escena.gd")

const TEXTURA_POR_TIPO: Dictionary = {
	InventoryItem.ItemType.MEMORY: preload("uid://o88v5s43wgiu"),  # fragmento_hilo_verde.png
	InventoryItem.ItemType.IMAGINATION: preload("uid://lw852yagnv86"),  # fragmento_hilo_amarillo.png
	InventoryItem.ItemType.SPIRIT: preload("uid://bhuboc30gq5k0"),  # fragmento_hilo_rojo.png
}
const COLOR_VERDE := Color(0.55, 1.0, 0.6)
const COLOR_AMARILLO := Color(1.0, 0.9, 0.45)
const COLOR_ROJO := Color(1.0, 0.5, 0.45)
const COLOR_BRILLO_POR_TIPO: Dictionary = {
	InventoryItem.ItemType.MEMORY: COLOR_VERDE,
	InventoryItem.ItemType.IMAGINATION: COLOR_AMARILLO,
	InventoryItem.ItemType.SPIRIT: COLOR_ROJO,
}
## fragmento_hilo_blanco.png
const TEXTURA_PERDON: Texture2D = preload("uid://btbo57cbklfhs")
const COLORES_AURA_PERDON: Array[Color] = [COLOR_VERDE, COLOR_AMARILLO, COLOR_ROJO]
const SEGUNDOS_POR_COLOR: float = 2.5
const ESCALA_AURA_PERDON: float = 1.8
const LATIDOS_POR_SEGUNDO_LEJOS: float = 0.5
const LATIDOS_POR_SEGUNDO_CERCA: float = 1.3
const DISTANCIA_LATIDO_CERCA: float = 120.0
const DISTANCIA_LATIDO_LEJOS: float = 700.0
const MOMENTO_GOLPE_1: float = 0.12
const ANCHURA_GOLPE_1: float = 0.07
const MOMENTO_GOLPE_2: float = 0.34
const ANCHURA_GOLPE_2: float = 0.08
const FUERZA_GOLPE_2: float = 0.6
const OPACIDAD_AURA_BASE: float = 0.4
const OPACIDAD_AURA_LATIDO: float = 0.4
const CRECIMIENTO_AURA_LATIDO: float = 0.2
const OPACIDAD_BRILLO_ALTA: float = 0.5
const OPACIDAD_BRILLO_BAJA: float = 0.25
const OPACIDAD_CENTRO_DEL_BRILLO: float = 0.9
const ALTURA_FLOTANDO: float = 6.0
const ESCALA_HILO: float = 0.8
const ESCALA_HILO_DEL_PERDON: float = 0.62
const DURACION_VAIVEN: float = 1.2
const TAMANO_TEXTURA_BRILLO: int = 128
const ANIMACION_REVELAR: StringName = &"reveal"
const ANIMACION_RECOGER: StringName = &"collected"

static var texturas_achicadas: Dictionary = {}

@export var revealed: bool = true:
	set(new_value):
		revealed = new_value
		_actualizar_segun_revelado()

@export_file("*.tscn") var next_scene: String

@export var item: InventoryItem:
	set = _set_item

@export var es_hilo_del_perdon: bool = false:
	set(new_value):
		es_hilo_del_perdon = new_value
		if sprite_2d:
			sprite_2d.texture = _textura_del_hilo()

@export_category("Dialogue")
@export var pause_game_during_dialogue: bool = false

@export var bloquear_salto_dialogo: bool = false

@export var collected_dialogue: DialogueResource:
	set(new_value):
		collected_dialogue = new_value
		notify_property_list_changed()

@export var dialogue_title: StringName = ""

var brillo: Sprite2D
var animacion_brillo: Tween
var fase_latido: float = 0.0
var tiempo_aura: float = 0.0
var _pauso_el_juego: bool = false

@onready var interact_area: InteractArea = $InteractArea
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var visuals: Node2D = %Visuals
@onready var sprite_2d: Sprite2D = $Visuals/Sprite2D
@onready var appear_sound: AudioStreamPlayer = %AppearSound
@onready var physical_collider: CollisionShape2D = $StaticBody2D/PhysicalCollider


func _validate_property(property: Dictionary) -> void:
	match property.name:
		"dialogue_title":
			if not collected_dialogue:
				property.usage |= PROPERTY_USAGE_READ_ONLY


func _get_configuration_warnings() -> PackedStringArray:
	if not item:
		return ["item property must be set"]
	return []


func _set_item(new_value: InventoryItem) -> void:
	item = new_value

	if sprite_2d:
		sprite_2d.texture = _textura_del_hilo()

	if interact_area:
		interact_area.action_text = "Collect " + item.type_name() if item else "Collect"

	update_configuration_warnings()


func _ready() -> void:
	_set_item(item)
	_quitar_decoracion_de_la_base()
	_actualizar_segun_revelado()

	if Engine.is_editor_hint():
		return

	interact_area.interaction_started.connect(_on_interacted)
	_brillar_y_flotar()


func _exit_tree() -> void:
	# Si el nivel se reinicia con el diálogo abierto, la pausa no se quitaría nunca.
	if _pauso_el_juego and is_inside_tree():
		get_tree().paused = false


func _process(delta: float) -> void:
	if not es_hilo_del_perdon or not is_instance_valid(brillo) or not brillo.visible:
		return

	tiempo_aura += delta
	fase_latido += (
		delta * lerpf(LATIDOS_POR_SEGUNDO_LEJOS, LATIDOS_POR_SEGUNDO_CERCA, _cercania_de_lino())
	)
	var latido := _fuerza_del_latido(fmod(fase_latido, 1.0))

	var color := _color_del_aura()
	color.a = OPACIDAD_AURA_BASE + OPACIDAD_AURA_LATIDO * latido
	brillo.modulate = color
	brillo.scale = Vector2.ONE * ESCALA_AURA_PERDON * (1.0 + CRECIMIENTO_AURA_LATIDO * latido)


func _color_del_aura() -> Color:
	var paso := tiempo_aura / SEGUNDOS_POR_COLOR
	var indice := int(paso) % COLORES_AURA_PERDON.size()
	var siguiente := (indice + 1) % COLORES_AURA_PERDON.size()
	return COLORES_AURA_PERDON[indice].lerp(COLORES_AURA_PERDON[siguiente], fmod(paso, 1.0))


func _cercania_de_lino() -> float:
	var lino := get_tree().get_first_node_in_group("player") as Node2D
	if not lino:
		return 0.0
	var distancia := global_position.distance_to(lino.global_position)
	return 1.0 - smoothstep(DISTANCIA_LATIDO_CERCA, DISTANCIA_LATIDO_LEJOS, distancia)


func _fuerza_del_latido(t: float) -> float:
	var golpe_1 := exp(-pow((t - MOMENTO_GOLPE_1) / ANCHURA_GOLPE_1, 2.0))
	var golpe_2 := exp(-pow((t - MOMENTO_GOLPE_2) / ANCHURA_GOLPE_2, 2.0))
	return golpe_1 + FUERZA_GOLPE_2 * golpe_2


func reveal() -> void:
	if revealed or animation_player.current_animation == ANIMACION_REVELAR:
		return

	appear_sound.play()
	animation_player.play(ANIMACION_REVELAR)
	await animation_player.animation_finished

	revealed = true


func _on_interacted(player: Player, _from_right: bool) -> void:
	_detener_brillo()
	z_index += 1
	animation_player.play(ANIMACION_RECOGER)
	await animation_player.animation_finished
	# Si un guardia atrapó a Lino mientras recogía el hilo, el nivel ya se está reiniciando:
	# no se cuenta el hilo ni se abre el diálogo, que dejaría el juego pausado.
	if player.mode == Player.Mode.DEFEATED:
		return

	var escena := get_tree().current_scene
	_registrar_recogida(escena)
	_lanzar_onda_de_color(escena)
	if collected_dialogue:
		await _mostrar_dialogo_de_recogida(player)

	interact_area.end_interaction()
	queue_free()

	if next_scene:
		GameState.quest.challenge_start_scene = next_scene
		SceneSwitcher.change_to_file_with_transition(next_scene)


func _registrar_recogida(escena: Node) -> void:
	var id_hilo := escena.scene_file_path + "::" + str(escena.get_path_to(self))
	if not ElHiloQueNoTejiState.hilos_contados.has(id_hilo):
		GameState.quest.inventory.add_collected_item(item)
	ElHiloQueNoTejiState.recolectar_hilo(id_hilo)
	ElHiloQueNoTejiState.guardar_ultimo_hilo(escena.scene_file_path, global_position)


func _lanzar_onda_de_color(escena: Node) -> void:
	var saturacion := escena.find_child("SaturacionManager", true, false)
	if es_hilo_del_perdon or not saturacion or not saturacion.has_method("onda_de_hilo"):
		return
	saturacion.onda_de_hilo(global_position, _color_del_brillo())


func _mostrar_dialogo_de_recogida(player: Player) -> void:
	if pause_game_during_dialogue:
		get_tree().paused = true
		_pauso_el_juego = true

	var bloqueo: BloqueoSaltoDialogo = null
	if bloquear_salto_dialogo:
		bloqueo = BloqueoSaltoDialogo.new(pause_game_during_dialogue)
		get_tree().current_scene.add_child(bloqueo)

	var globo: Node = DialogueManager.show_dialogue_balloon(
		collected_dialogue, dialogue_title, [self, player]
	)
	if pause_game_during_dialogue and globo:
		globo.process_mode = Node.PROCESS_MODE_ALWAYS

	await DialogueManager.dialogue_ended

	if bloqueo:
		bloqueo.queue_free()
	if pause_game_during_dialogue:
		get_tree().paused = false
		_pauso_el_juego = false


func _brillar_y_flotar() -> void:
	brillo = Sprite2D.new()
	brillo.texture = AyudasDeEscena.textura_de_halo(
		TAMANO_TEXTURA_BRILLO, OPACIDAD_CENTRO_DEL_BRILLO
	)
	brillo.material = AyudasDeEscena.material_de_suma()
	brillo.show_behind_parent = true
	brillo.modulate = _color_del_brillo()
	brillo.modulate.a = OPACIDAD_BRILLO_ALTA
	sprite_2d.add_child(brillo)

	if es_hilo_del_perdon:
		return

	animacion_brillo = create_tween().set_loops().set_parallel(true)
	_agregar_vaiven(sprite_2d, "offset:y", -ALTURA_FLOTANDO, 0.0)
	_agregar_vaiven(brillo, "position:y", -ALTURA_FLOTANDO, 0.0)
	_agregar_vaiven(brillo, "modulate:a", OPACIDAD_BRILLO_BAJA, OPACIDAD_BRILLO_ALTA)


func _agregar_vaiven(nodo: Node, propiedad: String, ida: float, vuelta: float) -> void:
	(
		animacion_brillo
		. tween_property(nodo, propiedad, ida, DURACION_VAIVEN)
		. set_trans(Tween.TRANS_SINE)
		. set_ease(Tween.EASE_IN_OUT)
	)
	(
		animacion_brillo
		. tween_property(nodo, propiedad, vuelta, DURACION_VAIVEN)
		. set_trans(Tween.TRANS_SINE)
		. set_ease(Tween.EASE_IN_OUT)
		. set_delay(DURACION_VAIVEN)
	)


func _color_del_brillo() -> Color:
	return COLOR_BRILLO_POR_TIPO.get(item.type, Color.WHITE) if item else Color.WHITE


func _quitar_decoracion_de_la_base() -> void:
	if Engine.is_editor_hint():
		return
	$Visuals/Shadow.texture = null
	$Visuals/Highlight.sprite_frames = null
	$Visuals/Tail.sprite_frames = null


func _detener_brillo() -> void:
	if animacion_brillo:
		animacion_brillo.kill()
	sprite_2d.offset.y = 0.0
	if is_instance_valid(brillo):
		brillo.hide()


func _textura_del_hilo() -> Texture2D:
	if not item:
		return null
	if es_hilo_del_perdon:
		return _achicar(TEXTURA_PERDON, ESCALA_HILO_DEL_PERDON)
	return _achicar(TEXTURA_POR_TIPO.get(item.type, item.world_texture), ESCALA_HILO)


## Se achica la imagen y no el sprite: las animaciones le cambian la escala.
static func _achicar(textura: Texture2D, escala: float) -> Texture2D:
	if not textura or is_equal_approx(escala, 1.0):
		return textura
	var clave := "%s@%s" % [textura.resource_path, escala]
	if texturas_achicadas.has(clave):
		return texturas_achicadas[clave]
	var imagen := textura.get_image()
	if not imagen:
		return textura
	if imagen.is_compressed():
		imagen.decompress()
	var ancho := maxi(int(round(imagen.get_width() * escala)), 1)
	var alto := maxi(int(round(imagen.get_height() * escala)), 1)
	imagen.resize(ancho, alto, Image.INTERPOLATE_NEAREST)
	var achicada := ImageTexture.create_from_image(imagen)
	texturas_achicadas[clave] = achicada
	return achicada


func _actualizar_segun_revelado() -> void:
	if interact_area:
		interact_area.disabled = not revealed
	if visuals:
		visuals.visible = revealed
	if physical_collider:
		physical_collider.disabled = not revealed
