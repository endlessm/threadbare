@tool
class_name CollectibleItem
extends SceneLink

@export var revealed: bool = true:
	set(new_value):
		revealed = new_value
		_update_based_on_revealed()

@export var item: InventoryItem:
	set = _set_item

@export_category("Dialogue")
@export var collected_dialogue: DialogueResource:
	set(new_value):
		collected_dialogue = new_value
		notify_property_list_changed()

@export var dialogue_title: StringName = ""

@onready var interact_area: InteractArea = $InteractArea
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var appear_sound: AudioStreamPlayer = %AppearSound
@onready var physical_collider: CollisionShape2D = $StaticBody2D/CollisionShape2D

func _validate_property(property: Dictionary) -> void:
	super._validate_property(property)
	match property.name:
		"dialogue_title":
			if not collected_dialogue:
				property.usage |= PROPERTY_USAGE_READ_ONLY

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := super._get_configuration_warnings()
	if not item:
		warnings.append("item property must be set")
	return warnings

func _set_item(new_value: InventoryItem) -> void:
	item = new_value
	if sprite_2d:
		sprite_2d.texture = item.get_world_texture() if item else null
	if interact_area:
		interact_area.action = "Collect " + item.type_name() if item else "Collect"
	update_configuration_warnings()

func _ready() -> void:
	super._ready()
	_set_item(item)
	_update_based_on_revealed()
	sprite_2d.modulate = Color.WHITE if revealed else Color.TRANSPARENT
	if Engine.is_editor_hint():
		return
	add_to_group("final_collectible")
	interact_area.interaction_started.connect(self._on_interacted)

func reveal() -> void:
	revealed = true
	appear_sound.play()
	animation_player.play("reveal")
	await animation_player.animation_finished

func _on_interacted(player: Player, _from_right: bool) -> void:
	z_index += 1
	animation_player.play("collected")
	await animation_player.animation_finished
	GameState.global.add_collected_item(item)
	if collected_dialogue:
		DialogueManager.show_dialogue_balloon(collected_dialogue, dialogue_title, [self, player])
		await DialogueManager.dialogue_ended
	interact_area.end_interaction()
	queue_free()
	if next_scene:
		if GameState.quest:
			GameState.quest.challenge_start_scene = next_scene
		else:
			push_warning("Collectible collected while not on a quest")
		switch()

func _update_based_on_revealed() -> void:
	if interact_area:
		interact_area.disabled = not revealed
	if sprite_2d:
		sprite_2d.visible = revealed
	if physical_collider:
		physical_collider.disabled = not revealed
