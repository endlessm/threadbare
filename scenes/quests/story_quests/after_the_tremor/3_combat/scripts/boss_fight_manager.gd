# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

@export var boss_node: NodePath = NodePath("Boss")
@export var auto_start_on_ready: bool = true

var _boss: Node = null
var _players_saved_stats: Dictionary = {} # <String, Dictionary>

func _ready() -> void:
	_boss = get_node_or_null(boss_node)
	if auto_start_on_ready:
		_start_fight()

func _start_fight() -> void:
	for p: Node in get_tree().get_nodes_in_group("player"):
		if not is_instance_valid(p):
			continue

		# Forzamos modo FIGHTING (1)
		if p.has_property("mode"):
			p.set("mode", 1)
		elif p.has_method("set_mode"):
			p.call("set_mode", 1)

		# Guardamos y cortamos velocidades
		var id: String = str(p.get_instance_id())
		if _players_saved_stats.has(id):
			continue

		var data: Dictionary = {}

		if p.has_property("walk_speed"):
			data["walk_speed"] = p.get("walk_speed")
			p.set("walk_speed", 0.0)

		if p.has_property("run_speed"):
			data["run_speed"] = p.get("run_speed")
			p.set("run_speed", 0.0)

		_players_saved_stats[id] = {
			"node": p,
			"data": data
		}

	# Arrancar boss si expone start()
	if _boss != null and _boss.has_method("start"):
		_boss.call("start")

func _unlock_players() -> void:
	for id_key: String in _players_saved_stats.keys():
		var entry: Dictionary = _players_saved_stats[id_key]
		if entry.is_empty():
			continue

		var p: Node = entry.get("node", null)
		var data: Dictionary = entry.get("data", {})

		if not is_instance_valid(p):
			continue

		# Restaurar velocidades
		if data.has("walk_speed") and p.has_property("walk_speed"):
			p.set("walk_speed", data["walk_speed"])

		if data.has("run_speed") and p.has_property("run_speed"):
			p.set("run_speed", data["run_speed"])

		# Restaurar modo COZY (0)
		if p.has_property("mode"):
			p.set("mode", 0)
		elif p.has_method("set_mode"):
			p.call("set_mode", 0)

	_players_saved_stats.clear()
