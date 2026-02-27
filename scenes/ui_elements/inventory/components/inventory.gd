# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends PanelContainer

signal back

@onready var tab_bar: TabBar = %TabBar
@onready var items_grid: GridContainer = %ItemsGrid
@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var inspect_panel: PanelContainer = %InspectPanel
@onready var inspect_icon: TextureRect = %InspectIcon
@onready var inspect_text: RichTextLabel = %InspectText
@onready var close_button: Button = %CloseButton
@onready var back_button: Button = %BackButton


func _ready() -> void:
	_populate_trinkets()
	GameState.trinket_collected.connect(_on_trinket_collected)
	GameState.trinket_removed.connect(_on_trinket_removed)
	_on_visibility_changed()


func _on_visibility_changed() -> void:
	if visible and back_button:
		_close_inspect()
		back_button.grab_focus()


func _populate_trinkets() -> void:
	_clear_grid()
	for trinket: Trinket in GameState.trinkets:
		_add_trinket_button(trinket)


func _add_trinket_button(trinket: Trinket) -> void:
	var button := TextureButton.new()
	button.texture_normal = trinket.icon
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.custom_minimum_size = Vector2(64, 64)
	button.tooltip_text = trinket.name
	button.pressed.connect(_on_trinket_pressed.bind(trinket))
	items_grid.add_child(button)


func _on_trinket_pressed(trinket: Trinket) -> void:
	inspect_icon.texture = trinket.icon
	if trinket.is_readable():
		inspect_icon.visible = false
		inspect_text.text = trinket.full_text
		inspect_text.visible = true
	else:
		inspect_text.visible = false
		inspect_icon.visible = true
	scroll_container.visible = false
	inspect_panel.visible = true
	close_button.grab_focus()


func _close_inspect() -> void:
	inspect_panel.visible = false
	scroll_container.visible = true


func _clear_grid() -> void:
	for child: Node in items_grid.get_children():
		child.queue_free()


func _on_trinket_collected(trinket: Trinket) -> void:
	_add_trinket_button(trinket)


func _on_trinket_removed(_trinket: Trinket) -> void:
	_populate_trinkets()


func _on_close_button_pressed() -> void:
	_close_inspect()


func _on_back_button_pressed() -> void:
	back.emit()
