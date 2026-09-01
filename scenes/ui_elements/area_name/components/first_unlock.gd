# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends PanelContainer


func _is_player_at_bottom() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not player:
		return false

	var viewport := player.get_viewport()
	var screen_pos: Vector2 = viewport.get_canvas_transform() * player.global_position
	var viewport_size: Vector2 = viewport.get_visible_rect().size

	return screen_pos.y > viewport_size.y * 3.0 / 4.0
func animate_first_unlock(text_content: String, time: int) -> void:
	var label = $Label

	show()
	label.text = text_content

	# Posicionar centrado y pegado a los bordes con su tamaño original
	if _is_player_at_bottom():
		# Jugador abajo → Pegado ARRIBA, centrado
		set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
		grow_vertical = Control.GROW_DIRECTION_END
		offset_top = 20.0 # Margen desde el borde superior
		offset_bottom = 20.0
	else:
		# Jugador arriba → Pegado ABAJO, centrado (sobre el HUD)
		set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		grow_vertical = Control.GROW_DIRECTION_BEGIN
		offset_bottom = -45.0 # Distancia desde la parte inferior (ajusta según el HUD)
		offset_top = -45.0

	# Esperar un frame para calcular el tamaño real del pergamino según el texto
	await get_tree().process_frame

	pivot_offset = size / 2.0
	scale = Vector2(1.0, 1.0)
	modulate.a = 0.0

	# FADE IN
	var tween_in := create_tween().set_parallel(true)
	tween_in.tween_property(self, "modulate:a", 1.0, 0.3)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_in.tween_property(self, "scale", Vector2(1.0, 1.0), 0.3)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await tween_in.finished

	# Mantener visible
	await get_tree().create_timer(time).timeout

	# FADE OUT
	var tween_out := create_tween().set_parallel(true)
	tween_out.tween_property(self, "modulate:a", 0.0, 0.35)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await tween_out.finished

	hide()
