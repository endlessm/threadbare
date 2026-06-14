class_name BossIntroCinematic
extends Cinematic

@export var player_path: NodePath
@export var boss_path: NodePath

func start() -> void:
	var player = get_node_or_null(player_path)
	var boss = get_node_or_null(boss_path)

	if player:
		player.set_process(false)
		player.set_physics_process(false)

	if boss:
		boss.set_process(false)
		boss.set_physics_process(false)

	DialogueManager.show_dialogue_balloon(dialogue, "", [self])
	await DialogueManager.dialogue_ended

	if player:
		player.set_process(true)
		player.set_physics_process(true)

	if boss:
		boss.set_process(true)
		boss.set_physics_process(true)

	cinematic_finished.emit()
