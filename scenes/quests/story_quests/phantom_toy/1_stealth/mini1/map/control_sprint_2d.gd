extends Node

var sprint_disponible := true
var sprint_usado := false

func _process(delta):
	var player = get_tree().get_first_node_in_group("player")

	if player == null:
		return

	if Input.is_action_just_pressed("running") and sprint_disponible:
		sprint_disponible = false
		iniciar_cooldown()


func iniciar_cooldown():
	await get_tree().create_timer(3.0).timeout

	Input.action_release("running")

	await get_tree().create_timer(15.0).timeout

	sprint_disponible = true
