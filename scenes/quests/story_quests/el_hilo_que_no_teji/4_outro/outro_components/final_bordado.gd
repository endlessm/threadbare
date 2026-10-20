# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Control
## El texto final del outro, sobre una tela.

const FinalHilo = preload("final_hilo.gd")
const SHADER_TELA: Shader = preload("../../shared/shaders/tela_del_final.gdshader")


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = SHADER_TELA
	material.set_shader_parameter("pantalla", get_viewport_rect().size)
	var tela := ColorRect.new()
	tela.material = material
	tela.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tela.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(tela)


func mostrar(etiqueta: RichTextLabel) -> void:
	etiqueta.hide()
	var lineas: Array[String] = []
	for linea in etiqueta.get_parsed_text().split("\n"):
		if not linea.strip_edges().is_empty():
			lineas.append(linea.strip_edges())
	var hilo := FinalHilo.new()
	add_child(hilo)
	await hilo.mostrar(FinalHilo.frases_para_el_idioma(lineas))
