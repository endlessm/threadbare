# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

signal goal_reached

@export var barrels_to_win: int = 1
@export var intro_dialogue: DialogueResource

var barrels_completed: int = 0
var _can_take_damage: bool = true  # Controla si el jugador puede recibir daño

func start() -> void:
	var player: Player = get_tree().get_first_node_in_group("player")
	if player:
		player.mode = Player.Mode.FIGHTING
	get_tree().call_group("throwing_enemy", "start")
	for filling_barrel: FillingBarrel in get_tree().get_nodes_in_group("filling_barrels"):
		filling_barrel.completed.connect(_on_barrel_completed)
	_update_allowed_colors()
	if Engine.is_editor_hint():
		return
	for guard: Guard in get_tree().get_nodes_in_group(&"guard_enemy"):
		guard.player_detected.connect(self._on_player_detected)

func _ready() -> void:
	var filling_barrels: Array = get_tree().get_nodes_in_group("filling_barrels")
	barrels_to_win = clampi(barrels_to_win, 3, filling_barrels.size())
	if intro_dialogue:
		var player: Player = get_tree().get_first_node_in_group("player")
		DialogueManager.show_dialogue_balloon(intro_dialogue, "", [self, player])
		await DialogueManager.dialogue_ended
	start()

func _update_allowed_colors() -> void:
	var allowed_labels: Array[String] = []
	var color_per_label: Dictionary[String, Color]
	for filling_barrel: FillingBarrel in get_tree().get_nodes_in_group("filling_barrels"):
		if filling_barrel.is_queued_for_deletion():
			continue
		if filling_barrel.label not in allowed_labels:
			allowed_labels.append(filling_barrel.label)
			if not filling_barrel.color:
				continue
			color_per_label[filling_barrel.label] = filling_barrel.color
	for enemy: ThrowingEnemy in get_tree().get_nodes_in_group("throwing_enemy"):
		enemy.allowed_labels = allowed_labels
		enemy.color_per_label = color_per_label

func _on_barrel_completed() -> void:
	barrels_completed += 1
	_update_allowed_colors()
	if barrels_completed < barrels_to_win:
		return
	get_tree().call_group("throwing_enemy", "remove")
	get_tree().call_group("projectiles", "remove")
	var player: Player = get_tree().get_first_node_in_group("player")
	if player:
		player.mode = Player.Mode.COZY
	goal_reached.emit()

func _on_player_detected(player: Player) -> void:
	print("=== FUNCIÓN LLAMADA ===")
	
	# Desconectar TODAS las señales de los guardias temporalmente
	for guard: Guard in get_tree().get_nodes_in_group(&"guard_enemy"):
		if guard.player_detected.is_connected(self._on_player_detected):
			guard.player_detected.disconnect(self._on_player_detected)
			print("Señal desconectada de ", guard.name)
	
	# Aplicar daño
	player.life -= 50
	print("¡Jugador detectado! Vida restante: ", player.life)
	
	if player.life <= 0:
		player.mode = Player.Mode.DEFEATED
		print("Jugador muerto, reiniciando nivel...")
		await get_tree().create_timer(2.0).timeout
		SceneSwitcher.reload_with_transition(Transition.Effect.FADE, Transition.Effect.FADE)
		return
	
	print("Esperando 2 segundos...")
	await get_tree().create_timer(2.0).timeout
	print("Reconectando señales...")
	
	for guard: Guard in get_tree().get_nodes_in_group(&"guard_enemy"):
		if not guard.player_detected.is_connected(self._on_player_detected):
			guard.player_detected.connect(self._on_player_detected)
			print("Señal reconectada a ", guard.name)
	
	print("=== FUNCIÓN TERMINADA ===")
