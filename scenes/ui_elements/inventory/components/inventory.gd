# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends PanelContainer

signal back

@onready var tab_bar: TabBar = %TabBar
@onready var items_grid: GridContainer = %ItemsGrid
@onready var back_button: Button = %BackButton


func _ready() -> void:
	_populate_trinkets()
	GameState.trinket_collected.connect(_on_trinket_collected)
	GameState.trinket_removed.connect(_on_trinket_removed)
	_on_visibility_changed()


func _on_visibility_changed() -> void:
	if visible and back_button:
		back_button.grab_focus()


func _populate_trinkets() -> void:
	_clear_grid()
	for trinket: Trinket in GameState.trinkets:
		_add_trinket_icon(trinket)


func _add_trinket_icon(trinket: Trinket) -> void:
	var icon := TextureRect.new()
	icon.texture = trinket.icon
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(64, 64)
	icon.tooltip_text = trinket.name
	items_grid.add_child(icon)


func _clear_grid() -> void:
	for child: Node in items_grid.get_children():
		child.queue_free()


func _on_trinket_collected(trinket: Trinket) -> void:
	_add_trinket_icon(trinket)


func _on_trinket_removed(_trinket: Trinket) -> void:
	_populate_trinkets()


func _on_back_button_pressed() -> void:
	back.emit()
