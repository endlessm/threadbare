# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name CollectibleItem extends Node2D

@export var revealed: bool = true:
	set(new_value):
		revealed = new_value
		_update_based_on_revealed()

@export_file("*.tscn") var next_scene: String
@export var item: InventoryItem:
	set = _set_item

@export_category("Dialogue")
@export var collected_dialogue: DialogueResource:
	set(new_value):
		collected_dialogue = new_value
		notify_property_list_changed()

@export var dialogue_title: StringName = ""
@export var unique_id: String = ""

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

	# Si ya estaba recogido → lanzar flujo directamente
	if unique_id != "" and GameState.has_collected(unique_id):
		await _call_after_collected(null)
		queue_free()

func reveal() -> void:
	revealed = true
	appear_sound.play()
	animation_player.play("reveal")

func _on_interacted(player: Player, _from_right: bool) -> void:
	# Solo dar el ítem si no lo teníamos
	if unique_id == "" or not GameState.has_collected(unique_id):
		z_index += 1
		animation_player.play("collected")
		await animation_player.animation_finished

		if unique_id != "":
			GameState.mark_collected(unique_id, item)
		else:
			GameState.add_collected_item(item)

	# Ejecutar flujo post-recolección
	await _call_after_collected(player)

	interact_area.end_interaction()
	queue_free()

func _call_after_collected(player: Player) -> void:
	if collected_dialogue:
		DialogueManager.show_dialogue_balloon(collected_dialogue, dialogue_title, [self, player])
		await DialogueManager.dialogue_ended

	if next_scene:
		SceneSwitcher.change_to_file_with_transition(next_scene)

func _update_based_on_revealed() -> void:
	if interact_area:
		interact_area.disabled = not revealed
	if sprite_2d:
		sprite_2d.visible = revealed
	if physical_collider:
		physical_collider.disabled = not revealed
