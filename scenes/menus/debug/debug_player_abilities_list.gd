# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends VBoxContainer


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	rebuild()


func _on_visibility_changed() -> void:
	if visible:
		rebuild()


func rebuild() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()

	for ability_name: String in Enums.PlayerAbilities.keys():
		var ability: Enums.PlayerAbilities = Enums.PlayerAbilities[ability_name]
		var button := CheckButton.new()
		button.text = ability_name
		button.button_pressed = GameState.has_ability(ability)
		button.toggled.connect(_on_button_toggled.bind(ability))
		add_child(button)


func _on_button_toggled(toggled_on: bool, ability: Enums.PlayerAbilities) -> void:
	GameState.set_ability(ability, toggled_on)
