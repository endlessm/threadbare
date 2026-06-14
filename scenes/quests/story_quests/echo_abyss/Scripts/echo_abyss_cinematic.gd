class_name BossIntroCinematic
extends Cinematic

@export var player_path: NodePath
# GameState.gd
var cinematic_active := false

func start() -> void:
	var player = get_node_or_null(player_path)
	var bosses = get_tree().get_nodes_in_group("bosses")
	print("inicio del dialogo")
	print(bosses)
	if player:
		player.set_process(false)
		player.set_physics_process(false)

	for boss in bosses:
		if boss:
			boss.set_process(false)
			boss.set_physics_process(false)

	DialogueManager.show_dialogue_balloon(dialogue, "", [self])
	await DialogueManager.dialogue_ended

	print("Fin del dialogo")
	for boss in bosses:
		if boss and boss.has_method("begin_fight"):
			boss.begin_fight()
		
	if player:
		player.set_process(true)
		player.set_physics_process(true)

	for boss in bosses:
		if boss:
			boss.set_process(true)
			boss.set_physics_process(true)

	cinematic_finished.emit()
