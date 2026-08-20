extends Node
@onready var sabio_area = $NPC/GuardArea;
@export_category("Dialogue")
@export var dialogue_title = "start";
@export var dialogue: DialogueResource:
	set(new_value):
		dialogue = new_value
		notify_property_list_changed()

func _ready() -> void:
	sabio_area.interaction_started.connect(_on_player_interaction);		

func _on_player_interaction(player: Player, from_right: bool)->void:
		DialogueManager.show_dialogue_balloon(dialogue, dialogue_title, [self, player])
		await DialogueManager.dialogue_ended
		sabio_area.end_interaction()
