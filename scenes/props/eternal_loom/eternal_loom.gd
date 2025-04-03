extends Node2D

const ETERNAL_LOOM_INTERACTION: DialogueResource = preload(
	"res://scenes/props/eternal_loom/eternal_loom_interaction.dialogue"
)
const ETERNAL_LOOM_SOKOBAN_PATH = "res://scenes/eternal_loom_sokoban/eternal_loom_sokoban.tscn"

@onready var interact_area: InteractArea = %InteractArea
@onready
var loom_offering_animation_player: AnimationPlayer = $LoomOfferingAnimation/LoomOfferingAnimationPlayer


func _ready():
	interact_area.interaction_started.connect(self._on_interacted)


func _on_interacted(_from_right: bool) -> void:
	var balloon = DialogueManager.show_dialogue_balloon(ETERNAL_LOOM_INTERACTION)
	await DialogueManager.dialogue_ended

	if is_item_offering_possible():
		DialogueManager.show_dialogue_balloon(ETERNAL_LOOM_INTERACTION, "offering_succeeded")
		loom_offering_animation_player.play("loom_offering")
		loom_offering_animation_player.animation_finished.connect(
			func(anim_name): self.on_loom_offering_complete()
		)
	else:
		DialogueManager.show_dialogue_balloon(ETERNAL_LOOM_INTERACTION, "offering_failed")
	await DialogueManager.dialogue_ended

	# This little wait is needed to avoid triggering another dialogue:
	# TODO: improve this in https://github.com/endlessm/threadbare/issues/103
	await get_tree().create_timer(0.3).timeout
	interact_area.end_interaction()


func _inventory() -> Inventory:
	return GameState.inventory


func _item_types_required() -> Array:
	return InventoryItem.item_types()


func is_item_offering_possible() -> bool:
	return _item_types_required().all(func(item_type): return _inventory().has_item_type(item_type))


func consume_items_offering() -> void:
	for item_type in _item_types_required():
		consume_item_of_type(item_type)


func consume_item_of_type(item_type: InventoryItem.ItemType):
	for item in GameState.items_collected():
		if item.type == item_type:
			GameState.remove_consumed_item(item)
			return


func on_loom_offering_complete():
	consume_items_offering()
	SceneSwitcher.change_to_file_with_transition(ETERNAL_LOOM_SOKOBAN_PATH)
