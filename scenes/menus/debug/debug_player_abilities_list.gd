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

	var abilities_names: Dictionary[Enums.PlayerAbilities, String] = LoreInfo.ABILITIES_NAMES
	if GameState.quest and GameState.quest.quest is StoryQuest:
		var sq := GameState.quest.quest as StoryQuest
		abilities_names = sq.abilities_names

	for ability_string: String in Enums.PlayerAbilities.keys():
		var ability: Enums.PlayerAbilities = Enums.PlayerAbilities[ability_string]
		var button := CheckButton.new()
		button.text = abilities_names.get(ability, ability_string)
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.clip_text = true
		button.button_pressed = GameState.player.has_ability(ability)
		button.toggled.connect(_on_button_toggled.bind(ability))
		add_child(button)


func _on_button_toggled(toggled_on: bool, ability: Enums.PlayerAbilities) -> void:
	GameState.player.set_ability(ability, toggled_on)
