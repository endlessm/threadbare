# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name CollectibleItem extends Node2D

## Overworld collectible that can be interacted with. When a player interacts
## with it, an [InventoryItem] is added to the [Inventory]

## Wether the collectible can be seen or collected. This allows the collectible
## to be placed in the scene even when some condition has to be met for it to
## appear.
@export var revealed: bool = true:
	set(new_value):
		revealed = new_value
		_update_based_on_revealed()
## If provided, switch to this scene after collecting and possibly displaying a dialogue.
@export_file("*.tscn") var scene_to_go_to: String
## [InventoryItem] provided by this collectible when interacted with.
@export var item: InventoryItem:
	set(new_value):
		item = new_value
		update_configuration_warnings()
@export_category("Dialogue")
## If provided, this dialogue will be displayed after the player collects this item.
@export var collected_dialogue: DialogueResource:
	set(new_value):
		collected_dialogue = new_value
		notify_property_list_changed()
## The dialogue title from where [member collected_dialogue] will start.
var dialogue_title: StringName = ""

@onready var interact_area: InteractArea = $InteractArea
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite_2d: Sprite2D = $Sprite2D


func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []

	if collected_dialogue:
		properties.push_back(
			{
				"name": "dialogue_title",
				"usage": PROPERTY_USAGE_DEFAULT,
				"type": TYPE_STRING,
				"hing": PROPERTY_HINT_PLACEHOLDER_TEXT,
				"hint_string": ""
			}
		)

	return properties


func _get_configuration_warnings() -> PackedStringArray:
	if not item:
		return ["item property must be set"]
	return []


func _ready() -> void:
	_update_based_on_revealed()
	if Engine.is_editor_hint():
		return

	interact_area.interaction_started.connect(self._on_interacted)


func _process(_delta: float) -> void:
	if item:
		sprite_2d.texture = item.texture()


## Make the collectible appear
func reveal() -> void:
	revealed = true
	animation_player.play("reveal")


## When interacted with, the collectible will display a brief animation
## and when that finishes, a new [InventoryItem] will be added to the
## [Inventory] and the interaction will have ended.
func _on_interacted(_from_right: bool) -> void:
	z_index += 1
	animation_player.play("collected")
	await animation_player.animation_finished

	GameState.add_collected_item(item)

	if collected_dialogue:
		DialogueManager.show_dialogue_balloon(collected_dialogue, dialogue_title, [self])
		await DialogueManager.dialogue_ended

	interact_area.end_interaction()
	queue_free()

	if scene_to_go_to:
		SceneSwitcher.change_to_file_with_transition(scene_to_go_to)


func _update_based_on_revealed() -> void:
	if interact_area:
		interact_area.disabled = not revealed
	if sprite_2d:
		sprite_2d.visible = revealed
