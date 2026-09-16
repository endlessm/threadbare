# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Area2D
var se_uso = false;	
@export_category("Dialogue")
@export var dialogue_title = "start";
@export var dialogue: DialogueResource:
	set(new_value):
		dialogue = new_value
		notify_property_list_changed()
@export var animation_player:AnimationPlayer		
signal dialogue_start;
signal dialogue_finished;		
		
func _ready() -> void:
	body_entered.connect(_on_body_entered);

func _on_body_entered(body:Node2D) -> void:
	if se_uso:
		return
	if body is Player:
		if dialogue:
			dialogue_start.emit();
			se_uso = true;
			var player: Player = body;
			player.take_control(self)
			player.velocity = Vector2.ZERO
			player.player_sprite.play("idle")
			DialogueManager.show_dialogue_balloon(dialogue, dialogue_title, [self, player])
			await DialogueManager.dialogue_ended
			player.return_control(self)	
		dialogue_finished.emit();
		queue_free();	
