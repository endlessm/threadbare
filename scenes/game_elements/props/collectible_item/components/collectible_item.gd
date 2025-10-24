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
@export_file("*.tscn") var next_scene: String

## [InventoryItem] provided by this collectible when interacted with.
@export var item: InventoryItem:
	set = _set_item

@export_category("Dialogue")

## If provided, this dialogue will be displayed after the player collects this item.
@export var collected_dialogue: DialogueResource:
	set(new_value):
		collected_dialogue = new_value
		notify_property_list_changed()

## The dialogue title from where [member collected_dialogue] will start.
@export var dialogue_title: StringName = ""

@onready var interact_area: InteractArea = $InteractArea
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var appear_sound: AudioStreamPlayer = %AppearSound
@onready var physical_collider: CollisionShape2D = $StaticBody2D/CollisionShape2D


func _validate_property(property: Dictionary) -> void:
	match property.name:
		"dialogue_title":
			if not collected_dialogue:
				property.usage |= PROPERTY_USAGE_READ_ONLY


func _get_configuration_warnings() -> PackedStringArray:
	if not item:
		return ["item property must be set"]
	return []


func _set_item(new_value: InventoryItem) -> void:
	item = new_value

	if sprite_2d:
		sprite_2d.texture = item.get_world_texture() if item else null

	if interact_area:
		interact_area.action = "Collect " + item.type_name() if item else "Collect"

	update_configuration_warnings()


func _ready() -> void:
	_set_item(item)
	_update_based_on_revealed()
	sprite_2d.modulate = Color.WHITE if revealed else Color.TRANSPARENT

	if Engine.is_editor_hint():
		return

	interact_area.interaction_started.connect(self._on_interacted)


## Make the collectible appear
func reveal() -> void:
	revealed = true
	appear_sound.play()
	animation_player.play("reveal")


## When interacted with, the collectible will display a brief animation
## and when that finishes, a new [InventoryItem] will be added to the
## [GameState] and the interaction will have ended.
func _on_interacted(player: Player, _from_right: bool) -> void:
	z_index += 1
	animation_player.play("collected")
	await animation_player.animation_finished

	GameState.add_collected_item(item)

	if collected_dialogue:
		DialogueManager.show_dialogue_balloon(collected_dialogue, dialogue_title, [self, player])
		await DialogueManager.dialogue_ended

	interact_area.end_interaction()
	queue_free()

	if next_scene:
		SceneSwitcher.change_to_file_with_transition(next_scene)


func _update_based_on_revealed() -> void:
	if interact_area:
		interact_area.disabled = not revealed
	if sprite_2d:
		sprite_2d.visible = revealed
	if physical_collider:
		physical_collider.disabled = not revealed
