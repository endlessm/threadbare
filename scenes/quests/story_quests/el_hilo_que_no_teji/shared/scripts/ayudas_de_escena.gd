# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends RefCounted
## Ayudas compartidas: halo de luz, rectángulo a pantalla completa, cámara y globo de diálogo.

const CENTRO_DEL_HALO := Vector2(0.5, 0.5)
const BORDE_DEL_HALO := Vector2(0.5, 0.0)


static func textura_de_halo(tamano: int, opacidad_central: float = 1.0) -> GradientTexture2D:
	var degradado := Gradient.new()
	degradado.set_color(0, Color(1.0, 1.0, 1.0, opacidad_central))
	degradado.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var textura := GradientTexture2D.new()
	textura.gradient = degradado
	textura.fill = GradientTexture2D.FILL_RADIAL
	textura.fill_from = CENTRO_DEL_HALO
	textura.fill_to = BORDE_DEL_HALO
	textura.width = tamano
	textura.height = tamano
	return textura


static func material_de_suma() -> CanvasItemMaterial:
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return material


static func rect_de_pantalla_completa() -> ColorRect:
	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	return rect


static func camara_como(camara_original: Camera2D) -> Camera2D:
	var camara := Camera2D.new()
	camara.global_position = camara_original.get_screen_center_position()
	camara.zoom = camara_original.zoom
	camara.limit_left = camara_original.limit_left
	camara.limit_right = camara_original.limit_right
	camara.limit_top = camara_original.limit_top
	camara.limit_bottom = camara_original.limit_bottom
	return camara


static func mostrar_globo_arriba(dialogo: DialogueResource, titulo: String) -> Node:
	var globo: Node = DialogueManager.show_dialogue_balloon(dialogo, titulo)
	if not is_instance_valid(globo):
		return null
	globo.set("will_block_other_input", false)
	if not globo.is_node_ready():
		await globo.ready
	if is_instance_valid(globo) and globo.get("balloon_container") != null:
		globo.anchor_to_top()
	return globo
