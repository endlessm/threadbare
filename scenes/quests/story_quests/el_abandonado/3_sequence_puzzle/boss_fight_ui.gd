# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Control

var player_label: Label
var boss_label: Label

var player_health_bar: ProgressBar
var boss_health_bar: ProgressBar

var player: Node = null
var boss: Node = null


func _ready() -> void:
	visible = true
	z_index = 100
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_create_ui()

	await get_tree().process_frame

	player = get_tree().get_first_node_in_group("player")
	boss = get_tree().get_first_node_in_group("boss")

	if player != null:
		if player.has_signal("health_changed"):
			player.health_changed.connect(_on_player_health_changed)

		var player_current_health = player.get("current_health")
		var player_max_health = player.get("max_health")

		if player_current_health != null and player_max_health != null:
			_on_player_health_changed(player_current_health, player_max_health)
	else:
		push_error("No se encontró Player en grupo player.")

	if boss != null:
		if boss.has_signal("health_changed"):
			boss.health_changed.connect(_on_boss_health_changed)

		var boss_current_health = boss.get("current_health")
		var boss_max_health = boss.get("max_health")

		if boss_current_health != null and boss_max_health != null:
			_on_boss_health_changed(boss_current_health, boss_max_health)

		if boss.has_signal("boss_defeated"):
			boss.boss_defeated.connect(_on_boss_defeated)
	else:
		push_error("No se encontró Alma del padre en grupo boss.")


func _create_ui() -> void:
	anchors_preset = Control.PRESET_FULL_RECT
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_create_player_ui()
	_create_boss_ui()

	print("Barras de vida creadas correctamente")


func _create_player_ui() -> void:
	player_label = Label.new()
	player_label.name = "PlayerNameLabel"
	add_child(player_label)

	player_label.text = "Brennan"
	player_label.position = Vector2(30, 8)
	player_label.size = Vector2(260, 22)
	player_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_label.add_theme_font_size_override("font_size", 18)
	player_label.add_theme_color_override("font_color", Color.WHITE)

	player_health_bar = ProgressBar.new()
	player_health_bar.name = "PlayerHealthBar"
	add_child(player_health_bar)

	player_health_bar.position = Vector2(30, 30)
	player_health_bar.size = Vector2(260, 26)
	player_health_bar.min_value = 0
	player_health_bar.max_value = 100
	player_health_bar.value = 100
	player_health_bar.show_percentage = false
	player_health_bar.visible = true
	player_health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_apply_red_bar_style(player_health_bar)


func _create_boss_ui() -> void:
	var screen_width := get_viewport_rect().size.x
	var boss_bar_width := 420.0
	var boss_bar_height := 26.0
	var margin_right := 30.0
	var boss_x := screen_width - boss_bar_width - margin_right
	var boss_y := 30.0

	boss_label = Label.new()
	boss_label.name = "BossNameLabel"
	add_child(boss_label)

	boss_label.text = "Father's soul"
	boss_label.position = Vector2(boss_x, 8)
	boss_label.size = Vector2(boss_bar_width, 22)
	boss_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_label.add_theme_font_size_override("font_size", 18)
	boss_label.add_theme_color_override("font_color", Color.WHITE)

	boss_health_bar = ProgressBar.new()
	boss_health_bar.name = "BossHealthBar"
	add_child(boss_health_bar)

	boss_health_bar.position = Vector2(boss_x, boss_y)
	boss_health_bar.size = Vector2(boss_bar_width, boss_bar_height)
	boss_health_bar.min_value = 0
	boss_health_bar.max_value = 800
	boss_health_bar.value = 800
	boss_health_bar.show_percentage = false
	boss_health_bar.visible = true
	boss_health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_apply_red_bar_style(boss_health_bar)


func _apply_red_bar_style(bar: ProgressBar) -> void:
	var background_style := StyleBoxFlat.new()
	background_style.bg_color = Color(0.12, 0.12, 0.12, 0.85)
	background_style.border_color = Color(0.85, 0.85, 0.85, 1.0)
	background_style.border_width_left = 2
	background_style.border_width_top = 2
	background_style.border_width_right = 2
	background_style.border_width_bottom = 2
	background_style.corner_radius_top_left = 6
	background_style.corner_radius_top_right = 6
	background_style.corner_radius_bottom_left = 6
	background_style.corner_radius_bottom_right = 6

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0.85, 0.05, 0.05, 1.0)
	fill_style.corner_radius_top_left = 5
	fill_style.corner_radius_top_right = 5
	fill_style.corner_radius_bottom_left = 5
	fill_style.corner_radius_bottom_right = 5

	bar.add_theme_stylebox_override("background", background_style)
	bar.add_theme_stylebox_override("fill", fill_style)


func _on_player_health_changed(current_health: int, max_health: int) -> void:
	if player_health_bar == null:
		return

	player_health_bar.max_value = max_health
	player_health_bar.value = current_health


func _on_boss_health_changed(current_health: int, max_health: int) -> void:
	if boss_health_bar == null:
		return

	boss_health_bar.max_value = max_health
	boss_health_bar.value = current_health


func _on_boss_defeated() -> void:
	if boss_health_bar != null:
		boss_health_bar.visible = false

	if boss_label != null:
		boss_label.visible = false
