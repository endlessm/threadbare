extends Node

@export var dialogo_final: DialogueResource
@export_file("*.tscn") var next_scene: String
@export var enemigo:BalderFuturo
@export var timer_time_stop:Timer
	
func enemigo_derrotado()->void:
	enemigo.timer.stop()
	timer_time_stop.stop()
	DialogueManager.show_dialogue_balloon(dialogo_final, "start", [self])
	await DialogueManager.dialogue_ended
	await enemigo.remove()
	GameState.set_challenge_start_scene(next_scene)
	SceneSwitcher.change_to_file_with_transition(next_scene)	
	
