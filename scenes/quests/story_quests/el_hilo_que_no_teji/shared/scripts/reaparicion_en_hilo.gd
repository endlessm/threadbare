# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name ReaparicionEnHilo
extends Node
## Al deshilarse, Lino vuelve al último hilo recogido del nivel.

signal termino

const ANIMACION_REVIVIR: StringName = &"revive"
const ANIMACION_REPOSO: StringName = &"idle"
const TIEMPO_MAXIMO: float = 4.0

const FRASES_AL_REVIVIR: Array[String] = [
	"Aún no te he olvidado, Manchitas...",
	"No volveré a quedarme dormido...",
	"Manchitas... ilumina mi camino...",
]
## texto_pensamiento.gd
const SCRIPT_PENSAMIENTO: Script = preload("uid://d1wyim6fdlfsh")
## Jersey20-Regular.ttf
const FUENTE_PENSAMIENTO: Font = preload("uid://c3bb7lmvdqc5e")
const SEGUNDOS_BURBUJA: float = 9.0
const FONDO_DE_LA_BURBUJA := Color(0, 0, 0, 0.35)
const REDONDEO_DE_LA_BURBUJA: int = 100
const MARGEN_HORIZONTAL: float = 24.0
const MARGEN_VERTICAL: float = 12.0
const TAMANO_DE_LETRA: int = 24
const GROSOR_DEL_CONTORNO: int = 5
const CAPA_DE_LA_BURBUJA: int = 10

## Si el nivel la pone y devuelve true, esta reaparición no dice su frase.
var omitir_frase: Callable = Callable()


func _ready() -> void:
	var escena := get_tree().current_scene.scene_file_path
	var es_reaparicion := ElHiloQueNoTejiState.registrar_carga_de_nivel(escena)
	var jugador := get_tree().get_first_node_in_group("player") as Player
	if not es_reaparicion or not jugador:
		queue_free()
		return
	_reaparecer(jugador, ElHiloQueNoTejiState.obtener_ultimo_hilo(escena))


func _reaparecer(jugador: Player, posicion: Variant) -> void:
	jugador.take_control(self)
	jugador.velocity = Vector2.ZERO
	if omitir_frase.is_null() or not omitir_frase.call():
		_decir_frase_al_revivir()

	var sprite: AnimatedSprite2D = jugador.get_node("%PlayerSprite")
	var animaciones: AnimationPlayer = jugador.get_node("AnimationPlayer")
	var tiene_animacion := sprite.sprite_frames.has_animation(ANIMACION_REVIVIR)

	# El AnimationPlayer del jugador fuerza "idle" en cada cuadro: se pausa.
	if tiene_animacion:
		animaciones.pause()
		animaciones.set_process(false)
		sprite.play(ANIMACION_REVIVIR)

	if posicion != null:
		# Se espera a que el nivel quite los hilos recogidos: evita aparecer sobre su colisión.
		await get_tree().physics_frame
		await get_tree().physics_frame
		jugador.teleport_to(posicion)

	if tiene_animacion:
		await _esperar_fin_de_revivir(sprite)
		if not is_inside_tree() or not is_instance_valid(jugador):
			return
		animaciones.set_process(true)
		animaciones.play(ANIMACION_REPOSO)

	jugador.return_control(self)
	termino.emit()
	queue_free()


func _esperar_fin_de_revivir(sprite: AnimatedSprite2D) -> void:
	var limite := Time.get_ticks_msec() + int(TIEMPO_MAXIMO * 1000)
	while (
		is_inside_tree()
		and sprite.is_playing()
		and sprite.animation == ANIMACION_REVIVIR
		and Time.get_ticks_msec() < limite
	):
		await get_tree().process_frame


func _decir_frase_al_revivir() -> void:
	var burbuja := _crear_burbuja()
	var capa := CanvasLayer.new()
	capa.layer = CAPA_DE_LA_BURBUJA
	capa.add_child(burbuja)
	get_tree().current_scene.add_child(capa)
	burbuja.mostrar_pensamiento(FRASES_AL_REVIVIR.pick_random())

	get_tree().create_timer(SEGUNDOS_BURBUJA).timeout.connect(capa.queue_free)


func _crear_burbuja() -> PanelContainer:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = FONDO_DE_LA_BURBUJA
	estilo.set_corner_radius_all(REDONDEO_DE_LA_BURBUJA)
	estilo.content_margin_left = MARGEN_HORIZONTAL
	estilo.content_margin_right = MARGEN_HORIZONTAL
	estilo.content_margin_top = MARGEN_VERTICAL
	estilo.content_margin_bottom = MARGEN_VERTICAL

	var burbuja := PanelContainer.new()
	burbuja.add_theme_stylebox_override("panel", estilo)
	burbuja.set_script(SCRIPT_PENSAMIENTO)

	var etiqueta := Label.new()
	etiqueta.name = "Label"
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	etiqueta.add_theme_font_override("font", FUENTE_PENSAMIENTO)
	etiqueta.add_theme_font_size_override("font_size", TAMANO_DE_LETRA)
	etiqueta.add_theme_color_override("font_color", Color.WHITE)
	etiqueta.add_theme_color_override("font_outline_color", Color.BLACK)
	etiqueta.add_theme_constant_override("outline_size", GROSOR_DEL_CONTORNO)
	burbuja.add_child(etiqueta)

	var temporizador := Timer.new()
	temporizador.name = "Timer"
	temporizador.one_shot = true
	etiqueta.add_child(temporizador)
	return burbuja
