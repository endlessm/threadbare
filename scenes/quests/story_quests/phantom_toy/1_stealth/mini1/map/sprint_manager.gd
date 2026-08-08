extends Node

var sprint_disponible := true
var usando_sprint := false

func _process(delta):
	var player = get_tree().get_first_node_in_group("player")

	if player == null:
		return

	var walk = player.find_child("InputWalkBehavior", true, false)

	if walk == null:
		return

	# Si empieza a correr y el sprint está disponible
	if Input.is_action_pressed("running") and sprint_disponible and !usando_sprint:
		iniciar_sprint(walk)


func iniciar_sprint(walk):
	usando_sprint = true
	sprint_disponible = false

	var velocidad_original = walk.speeds.run_speed

	# Puede correr 3 segundos
	await get_tree().create_timer(3.0).timeout

	# Se bloquea el sprint
	walk.speeds.run_speed = walk.speeds.walk_speed

	# Cooldown de 15 segundos
	await get_tree().create_timer(15.0).timeout

	# Vuelve el sprint
	walk.speeds.run_speed = velocidad_original

	sprint_disponible = true
	usando_sprint = false
