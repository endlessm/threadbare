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

@onready var interact_area: InteractArea = $InteractArea
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var appear_sound: AudioStreamPlayer = %AppearSound
@onready var physical_collider: CollisionShape2D = $StaticBody2D/CollisionShape2D


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	_set_item(item)
	_update_based_on_revealed()

	# protección contra null
	if is_instance_valid(sprite_2d):
		sprite_2d.modulate = Color.WHITE if revealed else Color.TRANSPARENT

	interact_area.interaction_started.connect(_on_interacted)


func _set_item(new_value: InventoryItem) -> void:
	item = new_value

	if is_instance_valid(sprite_2d):
		sprite_2d.play("flotando")

	if is_instance_valid(interact_area):
		interact_area.action = "Leer pergamino"

	update_configuration_warnings()


func reveal() -> void:
	revealed = true
	if appear_sound:
		appear_sound.play()

	if animation_player:
		animation_player.play("reveal")
		await animation_player.animation_finished


func _on_interacted(player: Player, _from_right: bool) -> void:
	z_index += 1

	if animation_player:
		animation_player.play("collected")
		await animation_player.animation_finished

	GameState.add_collected_item(item)

	if collected_dialogue:
		DialogueManager.show_dialogue_balloon(
			collected_dialogue,
			dialogue_title,
			[self, player]
		)
		await DialogueManager.dialogue_ended

	interact_area.end_interaction()
	queue_free()

	if next_scene != "":
		GameState.set_challenge_start_scene(next_scene)
		SceneSwitcher.change_to_file_with_transition(next_scene)


func _update_based_on_revealed() -> void:
	if interact_area:
		interact_area.disabled = not revealed

	if sprite_2d:
		sprite_2d.visible = revealed

	if physical_collider:
		physical_collider.disabled = not revealed
