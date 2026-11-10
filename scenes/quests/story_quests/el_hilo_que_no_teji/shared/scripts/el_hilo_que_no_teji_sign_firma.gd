# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends "res://scenes/game_elements/props/sign/components/sign.gd"
## Carteles del quest, con la tecla necesaria en la firma.

const TECLAS_QUE_SE_MANTIENEN: Array[String] = ["shift"]
const TIEMPO_ARRIBA: float = 0.8
const TIEMPO_ABAJO: float = 1.2
const HUNDIMIENTO: int = 3
const COLOR_HUNDIDA := Color(0.22, 0.22, 0.24, 1)
const NODO_DIBUJO: String = "Appearance"
const NODO_ETIQUETA: String = "%Label"
const NODO_TEXTO_CON_FORMATO: String = "TextoConFormato"
const NODO_FILA_FIRMA: String = "%FilaFirma"
const NODO_TECLA: String = "%Tecla"

@export var firma: String = "":
	set(nueva_firma):
		firma = nueva_firma
		_actualizar_firma()


func _ready() -> void:
	super._ready()
	_actualizar_firma()
	if not Engine.is_editor_hint():
		_hundir_la_tecla_si_se_mantiene()


func update_appearance() -> void:
	var dibujo := get_node_or_null(NODO_DIBUJO) as Sprite2D
	if dibujo:
		dibujo.flip_h = direction == Enums.LookAtSide.RIGHT


func update_label_text() -> void:
	var etiqueta := get_node_or_null(NODO_ETIQUETA) as Label
	if not etiqueta:
		return
	var con_formato := (
		etiqueta.get_parent().get_node_or_null(NODO_TEXTO_CON_FORMATO) as RichTextLabel
	)
	if not text.contains("["):
		etiqueta.text = text
		etiqueta.show()
		if con_formato:
			con_formato.hide()
		return
	if not con_formato:
		con_formato = _crear_texto_con_formato(etiqueta)
	con_formato.text = text
	con_formato.show()
	etiqueta.hide()


func _crear_texto_con_formato(etiqueta: Label) -> RichTextLabel:
	var con_formato := RichTextLabel.new()
	con_formato.name = NODO_TEXTO_CON_FORMATO
	con_formato.bbcode_enabled = true
	con_formato.fit_content = true
	con_formato.scroll_active = false
	con_formato.mouse_filter = Control.MOUSE_FILTER_IGNORE
	con_formato.autowrap_mode = etiqueta.autowrap_mode
	con_formato.custom_minimum_size = etiqueta.custom_minimum_size
	con_formato.size_flags_horizontal = etiqueta.size_flags_horizontal
	con_formato.add_theme_font_override("normal_font", etiqueta.get_theme_font("font"))
	con_formato.add_theme_font_size_override(
		"normal_font_size", etiqueta.get_theme_font_size("font_size")
	)
	con_formato.add_theme_color_override("default_color", etiqueta.get_theme_color("font_color"))
	con_formato.add_theme_color_override(
		"font_outline_color", etiqueta.get_theme_color("font_outline_color")
	)
	con_formato.add_theme_constant_override(
		"outline_size", etiqueta.get_theme_constant("outline_size")
	)
	con_formato.add_theme_constant_override(
		"line_separation", etiqueta.get_theme_constant("line_spacing")
	)
	etiqueta.add_sibling(con_formato)
	return con_formato


func _actualizar_firma() -> void:
	var fila := get_node_or_null(NODO_FILA_FIRMA) as Control
	var tecla := get_node_or_null(NODO_TECLA) as Label
	if not fila or not tecla:
		return
	tecla.text = firma.trim_prefix("-").strip_edges()
	fila.visible = not tecla.text.is_empty()


func _hundir_la_tecla_si_se_mantiene() -> void:
	var tecla := get_node_or_null(NODO_TECLA) as Label
	if not tecla or tecla.text.to_lower() not in TECLAS_QUE_SE_MANTIENEN:
		return
	var caja := tecla.get_parent() as PanelContainer
	var original := caja.get_theme_stylebox("panel") as StyleBoxFlat if caja else null
	if not original:
		return
	var arriba := original.duplicate() as StyleBoxFlat
	arriba.border_width_bottom = original.border_width_bottom + HUNDIMIENTO
	var abajo := original.duplicate() as StyleBoxFlat
	abajo.content_margin_top = original.content_margin_top + HUNDIMIENTO
	abajo.bg_color = COLOR_HUNDIDA
	caja.add_theme_stylebox_override("panel", arriba)
	var pulsar := create_tween().set_loops()
	pulsar.tween_interval(TIEMPO_ARRIBA)
	pulsar.tween_callback(caja.add_theme_stylebox_override.bind("panel", abajo))
	pulsar.tween_interval(TIEMPO_ABAJO)
	pulsar.tween_callback(caja.add_theme_stylebox_override.bind("panel", arriba))
