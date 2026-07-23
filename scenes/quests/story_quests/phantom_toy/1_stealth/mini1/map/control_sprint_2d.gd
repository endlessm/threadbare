extends Node

var sprint_disponible := true
var velocidad_correr_original := 0.0


func _ready() -> void:
	var player = get_tree().get_first_node_in_group("player")

	if player != null:
		velocidad_correr_original = player.input_walk_behavior.speeds.run_speed


func _process(_delta):
	var player = get_tree().get_first_node_in_group("player")

	if player == null:
		return

	if Input.is_action_just_pressed("running") and sprint_disponible:
		sprint_disponible = false
		iniciar_cooldown(player)


func iniciar_cooldown(player):

	player.input_walk_behavior.speeds.run_speed = velocidad_correr_original

	await get_tree().create_timer(3.0).timeout

	
	player.input_walk_behavior.speeds.run_speed = player.input_walk_behavior.speeds.walk_speed

	# Esperar 15 segundos de cooldown
	await get_tree().create_timer(15.0).timeout

	
	player.input_walk_behavior.speeds.run_speed = velocidad_correr_original
	sprint_disponible = true
