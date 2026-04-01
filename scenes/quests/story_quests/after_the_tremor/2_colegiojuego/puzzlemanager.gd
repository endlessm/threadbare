# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

@export var zone_nodes: Array[AllHooked] = []
@export var timer_node: NodePath                    
@export var timer_seconds: int = 180                
@export var timer_label: NodePath = NodePath("")    
@export var auto_start_on_first_zone: bool = true
@export var final_collectible: NodePath
@export var final_dialogue: DialogueResource
@export var start_on_ready: bool = true
@export var player_node: NodePath = NodePath("")


@export var cable_group_name: String = "hookable_cable"

signal puzzle_succeeded
signal puzzle_failed

var _zones_done: Dictionary = {}   
var _timer: Timer = null
var _running: bool = false


func _ready() -> void:

	for n in zone_nodes:
		n.all_hooked.connect(_on_zone_all_hooked.bind(n))
		_zones_done[n] = false


	_timer = get_node_or_null(timer_node) as Timer
	if _timer:
		_timer.wait_time = timer_seconds
		_timer.one_shot = true
		var cbt := Callable(self, "_on_timer_timeout")
		if not _timer.is_connected("timeout", cbt):
			_timer.connect("timeout", cbt)


	if timer_label != NodePath(""):
		var lab := get_node_or_null(timer_label) as Label
		if lab:
			_update_timer_label(timer_seconds)

	if start_on_ready:
		start_puzzle()


func start_puzzle(_body: Node = null) -> void:
	if _running:
		return
	_running = true


	for k in _zones_done.keys():
		_zones_done[k] = false

	if _timer:
		_timer.start(timer_seconds)

	set_process(true)


func _on_zone_all_hooked(zone_node: Node) -> void:

	if not _running:
		if auto_start_on_first_zone:
			start_puzzle()
		else:
			return

	_zones_done[zone_node] = true


	_light_up_cables(zone_node)

	_check_success_condition()


func _check_success_condition() -> void:
	for v in _zones_done.values():
		if not v:
			return
	_success()


func _success() -> void:
	_running = false
	if _timer:
		_timer.stop()

	# Diálogo final
	if final_dialogue:
		DialogueManager.show_dialogue_balloon(final_dialogue, "", [])
		await DialogueManager.dialogue_ended


	if final_collectible != NodePath(""):
		var col := get_node_or_null(final_collectible)
		if col and col.has_method("reveal"):
			col.reveal()

	emit_signal("puzzle_succeeded")


	if timer_label != NodePath(""):
		var lab := get_node_or_null(timer_label) as Label
		if lab:
			lab.text = "¡Completado!"

	set_process(false)


func _on_timer_timeout() -> void:
	_running = false
	emit_signal("puzzle_failed")

	_reset_zones_state()


	if final_collectible != NodePath(""):
		var col := get_node_or_null(final_collectible)
		if col:
			col.revealed = false

	if timer_label != NodePath(""):
		var lab := get_node_or_null(timer_label) as Label
		if lab:
			lab.text = "Tiempo agotado. Reiniciando..."

	await get_tree().create_timer(0.8).timeout
	get_tree().reload_current_scene()


func _reset_zones_state() -> void:
	for n in zone_nodes:
		_reset_cables(n)
		_zones_done[n] = false


func _process(delta: float) -> void:
	if _running and _timer:
		_update_timer_label(ceil(_timer.time_left))


func _update_timer_label(seconds_left: int) -> void:
	var lab := get_node_or_null(timer_label) as Label
	if not lab:
		return
	var m := int(seconds_left / 60)
	var s := int(seconds_left % 60)
	lab.text = _zero(m) + ":" + _zero(s)



func _zero(n: int) -> String:
	return str(n) if n >= 10 else "0" + str(n)



func _collect_cables_recursive(node: Node, out_array: Array) -> void:
	for child in node.get_children():

		if child.has_method("turn_on"):
			out_array.append(child)
		elif cable_group_name != "" and child.is_in_group(cable_group_name):
			out_array.append(child)

		elif child is StaticBody2D and child.has_node("Sprite2D"):
			out_array.append(child)
		# recursión
		_collect_cables_recursive(child, out_array)



func _light_up_cables(zone_node: AllHooked) -> void:
	for c in zone_node.elements:
		if c.has_method("turn_on"):
			c.turn_on()
			print("PuzzleManager: encendiendo cable -> ", c.get_path())


func _reset_cables(zone_node: AllHooked) -> void:
	for c in zone_node.elements:
		if c.has_method("turn_off"):
			c.turn_off()
