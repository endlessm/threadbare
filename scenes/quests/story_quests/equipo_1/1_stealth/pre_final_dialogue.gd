extends Area2D
var se_uso = false;	
@export_category("Dialogue")
@export var dialogue_title = "start";
@export var pre_final_dialogue: DialogueResource:
	
	set(new_value):
		pre_final_dialogue = new_value
		notify_property_list_changed()
signal dialogue_start;
signal dialogue_finished;		
		
func _ready() -> void:
	body_entered.connect(_on_body_entered);

func _on_body_entered(body:Node2D) -> void:
		if se_uso:
			return
			
		if body is Player:
			dialogue_start.emit();
			se_uso = true;
			var player: Player = body;
			player.take_control(self)
			if(pre_final_dialogue):
				DialogueManager.show_dialogue_balloon(pre_final_dialogue, dialogue_title, [self, player])
				await DialogueManager.dialogue_ended
			player.return_control(self)	
			dialogue_finished.emit();
			queue_free();	
